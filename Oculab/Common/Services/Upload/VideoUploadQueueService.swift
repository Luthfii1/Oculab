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

    init() {}

    deinit {
        connectivityTask?.cancel()
    }

    func configure(
        modelContext: ModelContext,
        examInteractor: ExamInteractor,
        networkRetryManager: NetworkRetryManager
    ) {
        self.modelContext = modelContext
        self.examInteractor = examInteractor
        self.networkRetryManager = networkRetryManager

        // A process killed during upload leaves a persisted `.uploading` row.
        // Only recover when no upload is currently running in this service.
        if !isProcessing {
            let uploads = (try? modelContext.fetch(FetchDescriptor<PendingUpload>())) ?? []
            for upload in uploads where upload.state == .uploading {
                upload.state = .pending
            }
            try? modelContext.save()
        }

        connectivityTask?.cancel()
        connectivityTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                } catch {
                    return
                }
                guard let self, !Task.isCancelled else { return }
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
        let existing = try fetchUpload(examinationId: normalizedExamId, context: modelContext)
        guard existing?.state != .uploading else {
            throw VideoUploadQueueError.uploadInProgress
        }
        let previousFilePath = existing?.localFilePath
        let destinationURL = try persistentFileURL(sourceURL: sourceURL)
        let fileManager = FileManager.default

        // Copy to a new file first so a failed replacement keeps the original video.
        try fileManager.copyItem(at: sourceURL, to: destinationURL)

        if let existing {
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
        if let previousFilePath, previousFilePath != destinationURL.path {
            try? fileManager.removeItem(atPath: previousFilePath)
        }
        await refreshPublishedState()
    }

    func retry(examinationId: String) async {
        guard let modelContext,
              let upload = try? fetchUpload(examinationId: examinationId.lowercased(), context: modelContext)
        else { return }

        guard upload.state != .uploading else { return }

        upload.state = .pending
        upload.retryCount = 0
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
            guard !Task.isCancelled, networkRetryManager?.isConnected != false else { return }
            if upload.retryCount >= maxRetryCount {
                upload.state = .failed
                if upload.lastError == nil {
                    upload.lastError = AppTextExam.uploadQueueMaxRetries
                }
                try? modelContext.save()
                continue
            }

            let fileURL = URL(fileURLWithPath: upload.localFilePath)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                upload.state = .failed
                upload.retryCount = maxRetryCount
                upload.lastError = AppTextExam.uploadQueueMissingFile
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

                let examinationId = upload.examinationId
                modelContext.delete(upload)
                try modelContext.save()
                try? FileManager.default.removeItem(at: fileURL)

                AnalysisTrackingStore.track(examinationId: examinationId)
                AnalysisRealtimeService.shared.subscribe(to: examinationId)
                await ExaminationNotificationService.shared.requestAuthorizationIfNeeded()

                uploadingExaminationId = nil
            } catch {
                if Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled {
                    upload.state = .pending
                    uploadingExaminationId = nil
                    try? modelContext.save()
                    return
                }
                upload.state = .failed
                upload.retryCount += 1
                upload.lastError = ErrorHandler.shared.handleError(error, context: .examination)
                uploadingExaminationId = nil
                try? modelContext.save()

                let delay = min(pow(2.0, Double(upload.retryCount)), 16.0)
                do {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } catch {
                    return
                }
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

    private func persistentFileURL(sourceURL: URL) throws -> URL {
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
        let fileExtension = sourceURL.pathExtension.isEmpty ? "mov" : sourceURL.pathExtension.lowercased()
        return directory.appendingPathComponent(UUID().uuidString).appendingPathExtension(fileExtension)
    }
}

enum VideoUploadQueueError: LocalizedError {
    case notConfigured
    case uploadInProgress

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Upload queue is not configured."
        case .uploadInProgress:
            return "This examination is already uploading."
        }
    }
}
