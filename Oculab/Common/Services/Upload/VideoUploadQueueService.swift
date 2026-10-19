//
//  VideoUploadQueueService.swift
//  Oculab
//

import Foundation
import SwiftData
import CryptoKit

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
    private let now: @MainActor () -> Date
    private let onAccepted: @MainActor (String) -> Void
    private let hashVideo: @MainActor (URL) async throws -> String

    private let maxRetryCount = 5
    private let pendingDirectoryName = "PendingUploads"

    init(sessionProvider: @escaping @MainActor () -> UploadQueueSession? = { AuthSessionManager.uploadQueueSession },
         now: @escaping @MainActor () -> Date = { Date() },
         onAccepted: @escaping @MainActor (String) -> Void = {
             AnalysisTrackingStore.track(examinationId: $0)
             AnalysisRealtimeService.shared.subscribe(to: $0)
         },
         hashVideo: @escaping @MainActor (URL) async throws -> String = { try await VideoUploadQueueService.sha256(of: $0) }) {
        self.sessionProvider = sessionProvider
        self.now = now
        self.onAccepted = onAccepted
        self.hashVideo = hashVideo
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
                upload.needsReconciliation = true
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
                upload.needsReconciliation = true
            }
            for upload in uploads where upload.ownerUserId == session?.ownerUserId && upload.ownerUserId != nil && upload.stopReason == .authentication {
                upload.stopReason = nil
                upload.state = .pending
                upload.nextAttemptAt = nil
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

    func nextAttemptAt(for examinationId: String) -> Date? {
        sessionDidChange()
        guard let modelContext, let owner = observedSession?.ownerUserId,
              let upload = try? fetchUpload(examinationId: examinationId.lowercased(), context: modelContext),
              upload.ownerUserId == owner else { return nil }
        return upload.nextAttemptAt
    }

    func requiresReplacementVideo(for examinationId: String) -> Bool {
        sessionDidChange()
        guard let modelContext, let owner = observedSession?.ownerUserId,
              let upload = try? fetchUpload(examinationId: examinationId.lowercased(), context: modelContext),
              upload.ownerUserId == owner else { return false }
        return upload.stopReason == .replaceVideo
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
        let checksum: String
        do {
            checksum = try await hashVideo(destinationURL)
            guard isCurrent(session) else { throw CancellationError() }
            let latest = try fetchUpload(examinationId: normalizedExamId, context: modelContext)
            guard latest?.persistentModelID == existing?.persistentModelID,
                  latest?.localFilePath == previousFilePath, latest?.state != .uploading else {
                throw VideoUploadQueueError.uploadInProgress
            }
        } catch {
            try? fileManager.removeItem(at: destinationURL)
            throw error
        }

        if let existing {
            existing.patientId = patientId
            existing.localFilePath = destinationURL.path
            existing.slideId = slideId
            existing.state = .pending
            existing.retryCount = 0
            existing.lastError = nil
            existing.createdAt = .now
            existing.submissionId = UUID().uuidString.lowercased()
            existing.videoSHA256 = checksum
            existing.needsReconciliation = false
            existing.nextAttemptAt = nil
            existing.transientRetryCount = 0
            existing.stopReason = nil
            existing.hasSubmissionConflict = false
        } else {
            let upload = PendingUpload(
                    examinationId: normalizedExamId,
                    patientId: patientId,
                    localFilePath: destinationURL.path,
                    slideId: slideId,
                    ownerUserId: session.ownerUserId
                )
            upload.submissionId = UUID().uuidString.lowercased()
            upload.videoSHA256 = checksum
            modelContext.insert(upload)
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
        upload.stopReason = nil
        upload.nextAttemptAt = nil
        upload.transientRetryCount = 0
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

        var inFlightIdentity: QueuedVideoIdentity?
        defer {
            // Cancellation may arrive after a successful receipt but before local cleanup.
            // Preserve the video for later reconciliation under its original owner.
            if let identity = inFlightIdentity,
               let upload = try? fetchUpload(examinationId: identity.examinationId, context: modelContext),
               identity.matches(upload), upload.state == .uploading {
                upload.state = .pending
                try? modelContext.save()
            }
            uploadingExaminationId = nil
            refreshPublishedState()
        }

        let descriptor = FetchDescriptor<PendingUpload>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        guard let uploads = try? modelContext.fetch(descriptor) else { return }

        for upload in uploads where upload.ownerUserId == session.ownerUserId && (upload.state == .pending || upload.state == .failed) {
            guard isCurrent(session), networkRetryManager?.isConnected != false else { return }
            guard upload.stopReason == nil, upload.nextAttemptAt.map({ $0 <= now() }) ?? true else { continue }
            if upload.submissionId == nil {
                // Existing owned rows gain a key but cannot claim an old unkeyed job.
                upload.submissionId = UUID().uuidString.lowercased()
            }
            let identity = QueuedVideoIdentity(upload)
            inFlightIdentity = identity
            let submissionId = identity.submissionId
            do {
                try modelContext.save()
                if upload.needsReconciliation {
                    let receipt = try await examInteractor.fetchSubmissionReceipt(examinationId: upload.examinationId, submissionId: submissionId)
                    guard isCurrent(session), identity.matches(upload) else { return }
                    guard receipt.matches(examinationId: upload.examinationId, submissionId: submissionId) else {
                        stop(upload, reason: .serviceUpdate, message: "examination.upload_receipt_unavailable".localized)
                        continue
                    }
                    switch receipt.state {
                    case "accepted":
                        try finishAccepted(upload, context: modelContext)
                        continue
                    case "pending":
                        schedule(upload, message: "examination.upload_confirming_receipt".localized, retryAfter: receipt.retryAfter ?? now().addingTimeInterval(15))
                        continue
                    default:
                        // No receipt for this key does not undo a definite conflict.
                        guard !upload.hasSubmissionConflict else {
                            stop(upload, reason: .permanent, message: "examination.upload_conflict".localized)
                            continue
                        }
                    }
                }
                if upload.retryCount >= maxRetryCount {
                    stop(upload, reason: .exhausted, message: AppTextExam.uploadQueueMaxRetries)
                    continue
                }
                let fileURL = URL(fileURLWithPath: upload.localFilePath)
                guard FileManager.default.fileExists(atPath: fileURL.path) else {
                    stop(upload, reason: .replaceVideo, message: AppTextExam.uploadQueueMissingFile)
                    continue
                }
                let checksum = try await hashVideo(fileURL)
                guard isCurrent(session), identity.matches(upload) else { return }
                guard upload.videoSHA256 == nil || upload.videoSHA256 == checksum else {
                    stop(upload, reason: .replaceVideo, message: "examination.upload_video_rejected".localized)
                    continue
                }
                upload.videoSHA256 = checksum
                try modelContext.save()
                upload.state = .uploading
                upload.needsReconciliation = true
                upload.nextAttemptAt = nil
                uploadingExaminationId = upload.examinationId
                try modelContext.save() // Persist uncertainty before sending any bytes.
                refreshPublishedState()
                let response = try await examInteractor.submitQueuedExamination(
                    videoFileURL: fileURL, examinationId: upload.examinationId, patientId: upload.patientId,
                    submissionId: submissionId, videoSHA256: upload.videoSHA256!
                )
                guard isCurrent(session), identity.matches(upload) else { return }
                guard response.data.submissionReceiptVersion == 1,
                      response.data.submissionId?.lowercased() == submissionId.lowercased(),
                      response.data.examinationId?.lowercased() == upload.examinationId.lowercased(),
                      response.data.attemptId.flatMap(UUID.init(uuidString:)) != nil else {
                    schedule(upload, message: "examination.upload_confirming_receipt".localized)
                    continue
                }
                if (response.httpStatusCode ?? response.code) == 201, response.data.state == "accepted" {
                    try finishAccepted(upload, context: modelContext)
                } else if (response.httpStatusCode ?? response.code) == 202, response.data.state == "pending" {
                    schedule(upload, message: "examination.upload_confirming_receipt".localized, retryAfter: response.retryAfter ?? now().addingTimeInterval(15))
                } else {
                    schedule(upload, message: "examination.upload_confirming_receipt".localized)
                }
            } catch {
                guard sessionProvider() == session, identity.matches(upload) else { return }
                if Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled {
                    upload.state = .pending
                    try? modelContext.save()
                    return
                }
                if isAuthenticationFailure(error) {
                    stop(upload, reason: .authentication, message: "examination.upload_queue_sign_in_required".localized)
                } else if error is UploadProtocolFailure, upload.state != .uploading {
                    stop(upload, reason: .serviceUpdate, message: "examination.upload_receipt_unavailable".localized)
                } else if let failure = error as? UploadHTTPFailure {
                    switch failure.statusCode {
                    case 429, 500...599:
                        schedule(upload, message: "examination.upload_service_busy".localized, retryAfter: failure.retryAfter)
                    case 409:
                        // A 409 can be a lost accepted response or a different video.
                        // Lookup distinguishes them; never clear based on exam status.
                        if upload.needsReconciliation && upload.state != .uploading {
                            stop(upload, reason: .permanent, message: "examination.upload_conflict".localized)
                        } else {
                            upload.needsReconciliation = true
                            upload.hasSubmissionConflict = true
                            schedule(upload, message: "examination.upload_confirming_receipt".localized)
                        }
                    case 404 where upload.needsReconciliation && upload.state != .uploading:
                        stop(upload, reason: .serviceUpdate, message: "examination.upload_receipt_unavailable".localized)
                    case 400, 413, 415, 422:
                        stop(upload, reason: .replaceVideo, message: "examination.upload_video_rejected".localized)
                    default:
                        stop(upload, reason: .permanent, message: "examination.upload_permission_rejected".localized)
                    }
                } else {
                    if upload.state == .uploading { upload.retryCount += 1 }
                    schedule(upload, message: "examination.upload_confirming_receipt".localized)
                }
            }
            uploadingExaminationId = nil
            try? modelContext.save()
            refreshPublishedState()
        }
    }

    /// SwiftData updates a retained model instance in place during replacement.
    /// Never let an old await's response mutate the newer video in that instance.
    private struct QueuedVideoIdentity {
        let modelId: PersistentIdentifier
        let examinationId: String
        let submissionId: String
        let localFilePath: String

        init(_ upload: PendingUpload) {
            modelId = upload.persistentModelID
            examinationId = upload.examinationId
            submissionId = upload.submissionId!
            localFilePath = upload.localFilePath
        }

        func matches(_ upload: PendingUpload) -> Bool {
            upload.persistentModelID == modelId && upload.examinationId == examinationId
                && upload.submissionId == submissionId && upload.localFilePath == localFilePath
        }
    }

    private func finishAccepted(_ upload: PendingUpload, context: ModelContext) throws {
        let examinationId = upload.examinationId
        let fileURL = URL(fileURLWithPath: upload.localFilePath)
        context.delete(upload)
        try context.save()
        try? FileManager.default.removeItem(at: fileURL)
        onAccepted(examinationId)
        uploadingExaminationId = nil
        refreshPublishedState()
    }

    private func schedule(_ upload: PendingUpload, message: String, retryAfter: Date? = nil) {
        upload.transientRetryCount = min(upload.transientRetryCount + 1, 12)
        let delay = min(15 * pow(2, Double(upload.transientRetryCount - 1)), 300)
        upload.state = .pending
        upload.stopReason = nil
        upload.lastError = message
        upload.nextAttemptAt = max(now().addingTimeInterval(delay), retryAfter ?? now())
        uploadingExaminationId = nil
        try? modelContext?.save()
        refreshPublishedState()
    }

    private func stop(_ upload: PendingUpload, reason: PendingUploadStopReason, message: String) {
        upload.state = .failed
        upload.stopReason = reason
        upload.lastError = message
        upload.nextAttemptAt = nil
        uploadingExaminationId = nil
        try? modelContext?.save()
        refreshPublishedState()
    }

    private func isAuthenticationFailure(_ error: Error) -> Bool {
        if case NetworkError.unauthorized = error { return true }
        if let failure = error as? UploadHTTPFailure, failure.statusCode == 401 { return true }
        return (error as? URLError)?.code == .userAuthenticationRequired
    }

    static func sha256(of fileURL: URL) async throws -> String {
        let task = Task.detached(priority: .utility) {
            let handle = try FileHandle(forReadingFrom: fileURL)
            defer { try? handle.close() }
            var hash = SHA256()
            while let data = try handle.read(upToCount: 1024 * 1024), !data.isEmpty {
                try Task.checkCancellation()
                hash.update(data: data)
            }
            return hash.finalize().map { String(format: "%02x", $0) }.joined()
        }
        return try await withTaskCancellationHandler { try await task.value } onCancel: { task.cancel() }
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
