//
//  VideoUploadQueueService.swift
//  Oculab
//

import Foundation
import SwiftData

@MainActor
final class VideoUploadQueueService: ObservableObject {
    static let shared = VideoUploadQueueService()

    @Published private(set) var pendingCount: Int = 0
    @Published private(set) var uploadingExaminationId: String?
    @Published private(set) var failedExaminationIds: Set<String> = []

    private var modelContext: ModelContext?
    private var examInteractor: ExamInteractor?
    private var networkRetryManager: NetworkRetryManager?
    private var isProcessing = false
    private var connectivityTask: Task<Void, Never>?

    private let maxRetryCount = 5
    private let pendingDirectoryName = "PendingUploads"

    private init() {}

    func configure(
        modelContext: ModelContext,
        examInteractor: ExamInteractor,
        networkRetryManager: NetworkRetryManager
    ) {
        self.modelContext = modelContext
        self.examInteractor = examInteractor
        self.networkRetryManager = networkRetryManager

        connectivityTask?.cancel()
        connectivityTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard networkRetryManager.isConnected else { continue }
                await self.processQueue()
            }
        }

        Task { await refreshPublishedState() }
    }

    func hasPendingUpload(for examinationId: String) -> Bool {
        failedExaminationIds.contains(examinationId.lowercased())
            || uploadingExaminationId?.lowercased() == examinationId.lowercased()
            || pendingExaminationIds().contains(examinationId.lowercased())
    }

    func uploadState(for examinationId: String) -> PendingUploadState? {
        guard let modelContext,
              let upload = try? fetchUpload(examinationId: examinationId.lowercased(), context: modelContext)
        else { return nil }
        return upload.state
    }

    func lastUploadError(for examinationId: String) -> String? {
        guard let modelContext,
              let upload = try? fetchUpload(examinationId: examinationId.lowercased(), context: modelContext)
        else { return nil }
        return upload.lastError
    }

    func enqueue(
        examinationId: String,
        patientId: String,
        slideId: String,
        sourceURL: URL
    ) async throws {
        guard let modelContext else {
            throw VideoUploadQueueError.notConfigured
        }

        let normalizedExamId = examinationId.lowercased()
        let destinationURL = try persistentFileURL(for: normalizedExamId)
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: sourceURL, to: destinationURL)

        if let existing = try fetchUpload(examinationId: normalizedExamId, context: modelContext) {
            existing.patientId = patientId
            existing.localFilePath = destinationURL.path
            existing.slideId = slideId
            existing.state = .pending
            existing.retryCount = 0
            existing.lastError = nil
            existing.createdAt = .now
        } else {
            modelContext.insert(
                PendingUpload(
                    examinationId: normalizedExamId,
                    patientId: patientId,
                    localFilePath: destinationURL.path,
                    slideId: slideId
                )
            )
        }

        try modelContext.save()
        await refreshPublishedState()
    }

    func retry(examinationId: String) async {
        guard let modelContext,
              let upload = try? fetchUpload(examinationId: examinationId.lowercased(), context: modelContext)
        else { return }

        upload.state = .pending
        upload.lastError = nil
        try? modelContext.save()
        await refreshPublishedState()
        await processQueue()
    }

    func processQueue() async {
        guard !isProcessing,
              networkRetryManager?.isConnected != false,
              let modelContext,
              let examInteractor
        else { return }

        isProcessing = true
        defer {
            isProcessing = false
            Task { await refreshPublishedState() }
        }

        let descriptor = FetchDescriptor<PendingUpload>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        guard let uploads = try? modelContext.fetch(descriptor) else { return }

        for upload in uploads where upload.state == .pending || upload.state == .failed {
            if upload.retryCount >= maxRetryCount {
                upload.state = .failed
                upload.lastError = AppTextExam.uploadQueueMaxRetries
                try? modelContext.save()
                continue
            }

            let fileURL = URL(fileURLWithPath: upload.localFilePath)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                modelContext.delete(upload)
                try? modelContext.save()
                continue
            }

            upload.state = .uploading
            uploadingExaminationId = upload.examinationId
            try? modelContext.save()
            await refreshPublishedState()

            do {
                _ = try await examInteractor.submitExamination(
                    videoFileURL: fileURL,
                    examinationId: upload.examinationId,
                    patientId: upload.patientId
                )

                try? FileManager.default.removeItem(at: fileURL)
                modelContext.delete(upload)
                try modelContext.save()

                AnalysisTrackingStore.track(examinationId: upload.examinationId)
                AnalysisRealtimeService.shared.subscribe(to: upload.examinationId)
                await ExaminationNotificationService.shared.requestAuthorizationIfNeeded()

                uploadingExaminationId = nil
            } catch {
                upload.state = .failed
                upload.retryCount += 1
                upload.lastError = ErrorHandler.shared.handleError(error, context: .examination)
                uploadingExaminationId = nil
                try? modelContext.save()

                let delay = min(pow(2.0, Double(upload.retryCount)), 16.0)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    // MARK: - Private

    private func refreshPublishedState() async {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<PendingUpload>()
        let uploads = (try? modelContext.fetch(descriptor)) ?? []
        pendingCount = uploads.filter { $0.state != .uploading }.count
        failedExaminationIds = Set(
            uploads
                .filter { $0.state == .failed }
                .map { $0.examinationId.lowercased() }
        )
    }

    private func pendingExaminationIds() -> Set<String> {
        guard let modelContext else { return [] }
        let descriptor = FetchDescriptor<PendingUpload>()
        let uploads = (try? modelContext.fetch(descriptor)) ?? []
        return Set(
            uploads
                .filter { $0.state == .pending || $0.state == .failed }
                .map { $0.examinationId.lowercased() }
        )
    }

    private func fetchUpload(examinationId: String, context: ModelContext) throws -> PendingUpload? {
        let normalized = examinationId.lowercased()
        var descriptor = FetchDescriptor<PendingUpload>(
            predicate: #Predicate { $0.examinationId == normalized }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func persistentFileURL(for examinationId: String) throws -> URL {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = support.appendingPathComponent(pendingDirectoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory.appendingPathComponent("\(examinationId).mov")
    }
}

enum VideoUploadQueueError: LocalizedError {
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Upload queue is not configured."
        }
    }
}
