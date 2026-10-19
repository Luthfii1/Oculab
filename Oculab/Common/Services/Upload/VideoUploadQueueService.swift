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
    private var processingTask: Task<Void, Never>?
    private var sessionObserver: NSObjectProtocol?
    private let sessionProvider: @MainActor () -> UploadQueueSession?
    private var observedSession: UploadQueueSession?

    private let maxRetryCount = 5
    private let pendingDirectoryName = "PendingUploads"

    init(sessionProvider: @escaping @MainActor () -> UploadQueueSession? = { AuthSessionManager.uploadQueueSession }) {
        self.sessionProvider = sessionProvider
        observedSession = sessionProvider()
        sessionObserver = NotificationCenter.default.addObserver(
            forName: AuthSessionManager.sessionDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            // AuthSessionManager posts session boundaries synchronously on the main actor.
            MainActor.assumeIsolated { self?.sessionDidChange() }
        }
    }

    deinit {
        connectivityTask?.cancel()
        processingTask?.cancel()
        if let sessionObserver { NotificationCenter.default.removeObserver(sessionObserver) }
    }

    func configure(
        modelContext: ModelContext,
        examInteractor: ExamInteractor,
        networkRetryManager: NetworkRetryManager
    ) {
        self.modelContext = modelContext
        self.examInteractor = examInteractor
        self.networkRetryManager = networkRetryManager

        sessionDidChange()
        // A process killed during upload leaves a persisted `.uploading` row.
        // Only recover when no upload is currently running in this service.
        if !isProcessing {
            let uploads = (try? modelContext.fetch(FetchDescriptor<PendingUpload>())) ?? []
            for upload in uploads where upload.state == .uploading && upload.ownerUserId == observedSession?.ownerUserId && upload.ownerUserId != nil {
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

        refreshPublishedState()
    }

    /// Auth boundaries also invalidate in-flight responses from a previous session.
    func sessionDidChange() {
        let session = sessionProvider()
        guard session != observedSession else { return }
        let previousOwner = observedSession?.ownerUserId
        observedSession = session
        processingTask?.cancel()
        if let modelContext {
            let uploads = (try? modelContext.fetch(FetchDescriptor<PendingUpload>())) ?? []
            // Also recover an owner's interrupted rows when they log back in after
            // a cold launch under another account (or with no account).
            for upload in uploads where upload.ownerUserId != nil && upload.state == .uploading
                && (upload.ownerUserId == previousOwner || upload.ownerUserId == session?.ownerUserId) {
                upload.state = .pending
            }
            try? modelContext.save()
        }
        uploadingExaminationId = nil
        refreshPublishedState()
    }

    func hasPendingUpload(for examinationId: String) -> Bool {
        sessionDidChange()
        return failedExaminationIds.contains(examinationId.lowercased())
            || uploadingExaminationId?.lowercased() == examinationId.lowercased()
            || pendingExaminationIds().contains(examinationId.lowercased())
    }

    func uploadState(for examinationId: String) -> PendingUploadState? {
        sessionDidChange()
        guard let modelContext,
              let upload = try? fetchUpload(examinationId: examinationId.lowercased(), context: modelContext)
        else { return nil }
        guard upload.ownerUserId == observedSession?.ownerUserId, upload.ownerUserId != nil else { return nil }
        return upload.state
    }

    func patientId(for examinationId: String) -> String? {
        sessionDidChange()
        guard let modelContext,
              let upload = try? fetchUpload(examinationId: examinationId.lowercased(), context: modelContext),
              let owner = observedSession?.ownerUserId, upload.ownerUserId == owner else { return nil }
        return upload.patientId
    }

    func lastUploadError(for examinationId: String) -> String? {
        sessionDidChange()
        guard let modelContext,
              let upload = try? fetchUpload(examinationId: examinationId.lowercased(), context: modelContext)
        else { return nil }
        guard upload.ownerUserId == observedSession?.ownerUserId, upload.ownerUserId != nil else { return nil }
        return upload.lastError
    }

    func hasSavedVideo(for examinationId: String) -> Bool {
        sessionDidChange()
        guard let modelContext, let owner = observedSession?.ownerUserId,
              let upload = try? fetchUpload(examinationId: examinationId.lowercased(), context: modelContext),
              upload.ownerUserId == owner else { return false }
        return FileManager.default.fileExists(atPath: upload.localFilePath)
    }

    func enqueue(
        examinationId: String,
        patientId: String,
        slideId: String,
        sourceURL: URL
    ) async throws {
        sessionDidChange()
        guard let modelContext else {
            throw VideoUploadQueueError.notConfigured
        }
        guard let session = observedSession else { throw VideoUploadQueueError.authenticationRequired }

        let normalizedExamId = examinationId.lowercased()
        let existing = try fetchUpload(examinationId: normalizedExamId, context: modelContext)
        if let existing, existing.ownerUserId == nil {
            throw VideoUploadQueueError.legacyOwnershipUnknown
        }
        guard existing == nil || existing?.ownerUserId == session.ownerUserId else {
            throw VideoUploadQueueError.differentOwner
        }
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
                    slideId: slideId,
                    ownerUserId: session.ownerUserId
                )
            )
        }

        try modelContext.save()
        if let previousFilePath, previousFilePath != destinationURL.path {
            try? fileManager.removeItem(atPath: previousFilePath)
        }
        refreshPublishedState()
    }

    func retry(examinationId: String) async {
        sessionDidChange()
        guard let modelContext,
              let upload = try? fetchUpload(examinationId: examinationId.lowercased(), context: modelContext)
        else { return }

        guard upload.ownerUserId != nil, upload.ownerUserId == observedSession?.ownerUserId,
              upload.state != .uploading else { return }

        upload.state = .pending
        upload.retryCount = 0
        upload.lastError = nil
        try? modelContext.save()
        refreshPublishedState()
        await processQueue()
    }

    func processQueue() async {
        sessionDidChange()
        guard !isProcessing, let session = observedSession else { return }
        isProcessing = true
        let task = Task { await performQueue(session: session) }
        processingTask = task
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
        processingTask = nil
        isProcessing = false
        refreshPublishedState()
    }

    private func isCurrent(_ session: UploadQueueSession) -> Bool {
        !Task.isCancelled && sessionProvider() == session
    }

    private func performQueue(session: UploadQueueSession) async {
        guard isCurrent(session), networkRetryManager?.isConnected != false,
              let modelContext,
              let examInteractor
        else { return }

        defer {
            // Cancellation may arrive after a successful receipt but before local cleanup.
            // Preserve the video for later reconciliation under its original owner.
            let uploads = (try? modelContext.fetch(FetchDescriptor<PendingUpload>())) ?? []
            for upload in uploads where upload.ownerUserId == session.ownerUserId && upload.state == .uploading {
                upload.state = .pending
            }
            try? modelContext.save()
            uploadingExaminationId = nil
            refreshPublishedState()
        }

        let descriptor = FetchDescriptor<PendingUpload>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        guard let uploads = try? modelContext.fetch(descriptor) else { return }

        for upload in uploads where upload.ownerUserId == session.ownerUserId && (upload.state == .pending || upload.state == .failed) {
            guard isCurrent(session), networkRetryManager?.isConnected != false else { return }
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
            refreshPublishedState()

            do {
                _ = try await examInteractor.submitExamination(
                    videoFileURL: fileURL,
                    examinationId: upload.examinationId,
                    patientId: upload.patientId
                )

                guard isCurrent(session) else { return }

                let examinationId = upload.examinationId
                modelContext.delete(upload)
                try modelContext.save()
                try? FileManager.default.removeItem(at: fileURL)

                AnalysisTrackingStore.track(examinationId: examinationId)
                AnalysisRealtimeService.shared.subscribe(to: examinationId)
                uploadingExaminationId = nil
                refreshPublishedState()
                await ExaminationNotificationService.shared.requestAuthorizationIfNeeded()
                guard isCurrent(session) else { return }
            } catch {
                guard sessionProvider() == session else { return }
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
                refreshPublishedState()

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

    private func refreshPublishedState() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<PendingUpload>()
        let owner = sessionProvider()?.ownerUserId
        let uploads = ((try? modelContext.fetch(descriptor)) ?? []).filter { owner != nil && $0.ownerUserId == owner }
        pendingCount = uploads.filter { $0.state != .uploading }.count
        failedExaminationIds = Set(
            uploads
                .filter { $0.state == .failed }
                .map { $0.examinationId.lowercased() }
        )
    }

    private func pendingExaminationIds() -> Set<String> {
        guard let modelContext, let owner = sessionProvider()?.ownerUserId else { return [] }
        let descriptor = FetchDescriptor<PendingUpload>()
        let uploads = (try? modelContext.fetch(descriptor)) ?? []
        return Set(
            uploads
                .filter { $0.ownerUserId == owner && ($0.state == .pending || $0.state == .failed) }
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
    case authenticationRequired
    case differentOwner
    case legacyOwnershipUnknown

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Upload queue is not configured."
        case .uploadInProgress:
            return "This examination is already uploading."
        case .authenticationRequired:
            return "examination.upload_queue_sign_in_required".localized
        case .differentOwner:
            return "examination.upload_queue_different_owner".localized
        case .legacyOwnershipUnknown:
            return "examination.upload_queue_legacy_owner".localized
        }
    }
}
