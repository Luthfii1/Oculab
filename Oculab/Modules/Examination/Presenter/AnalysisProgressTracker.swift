//
//  AnalysisProgressTracker.swift
//  Oculab
//
//  Owns realtime + polling progress state for an examination analysis.
//  AnalysisResultPresenter composes this so UI state stays in one place
//  while progress lifecycle is testable on its own.
//

import Foundation

@MainActor
final class AnalysisProgressTracker: ObservableObject {
    @Published var analysisProgress: Int = 0
    @Published var analysisStatusMessage: String = AppTextExamProgress.analyzingTitle
    @Published var analysisFailureMessage: String?
    @Published var hasAnalysisFailed: Bool = false

    private let progressInteractor: AnalysisProgressInteractor
    private var progressObserver: NSObjectProtocol?
    private var trackingTask: Task<Void, Never>?
    private var trackedExaminationId: String?
    private var analysisTrackingStartedAt: Date?
    private var lastProgressChangeAt: Date?

    private let analysisStallTimeout: TimeInterval = 10 * 60
    private let analysisMaxDuration: TimeInterval = 30 * 60
    private let fovLoadStallTimeout: TimeInterval = 5 * 60

    var onReadyForValidation: ((String) async -> Void)?
    var onFailed: ((String, String) -> Void)?
    var onProgressChange: (() -> Void)?

    init(progressInteractor: AnalysisProgressInteractor = AnalysisProgressInteractor()) {
        self.progressInteractor = progressInteractor
    }

    func beginTracking(examinationId: String) {
        trackedExaminationId = examinationId
        analysisTrackingStartedAt = Date()
        lastProgressChangeAt = Date()
        hasAnalysisFailed = false
        analysisFailureMessage = nil
        startRealtimeTracking(examinationId: examinationId)
        Task { await loadCachedProgress(examinationId: examinationId) }
    }

    func stopTracking() {
        trackingTask?.cancel()
        trackingTask = nil
        stopRealtimeTracking()
        trackedExaminationId = nil
        analysisTrackingStartedAt = nil
        lastProgressChangeAt = nil
    }

    func startRealtimeTracking(examinationId: String) {
        Task {
            await ExaminationNotificationService.shared.requestAuthorizationIfNeeded()
        }

        AnalysisRealtimeService.shared.subscribe(to: examinationId)

        progressObserver = NotificationCenter.default.addObserver(
            forName: .examinationAnalysisProgress,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let update = notification.userInfo?["update"] as? AnalysisProgressUpdate,
                  update.examId.lowercased() == examinationId.lowercased()
            else {
                return
            }

            Task { @MainActor in
                self.applyProgressUpdate(update, examinationId: examinationId)
                if update.isFailed { return }
                if update.isReadyForValidation {
                    await self.onReadyForValidation?(examinationId)
                }
            }
        }
    }

    func stopRealtimeTracking() {
        if let progressObserver {
            NotificationCenter.default.removeObserver(progressObserver)
            self.progressObserver = nil
        }
    }

    func applyProgressUpdate(_ update: AnalysisProgressUpdate, examinationId: String) {
        if update.isFailed {
            markFailed(message: update.message, examinationId: examinationId)
            return
        }

        if update.progress != analysisProgress {
            lastProgressChangeAt = Date()
        }

        analysisProgress = update.progress
        if let message = update.message, !message.isEmpty {
            analysisStatusMessage = message
        }
        onProgressChange?()
    }

    func markFailed(message: String?, examinationId: String) {
        hasAnalysisFailed = true
        let resolved = (message?.isEmpty == false)
            ? message!
            : AppTextExamProgress.analysisFailedDefault
        analysisFailureMessage = resolved
        analysisStatusMessage = resolved
        onFailed?(examinationId, resolved)
        stopTracking()
    }

    func clearFailure() {
        hasAnalysisFailed = false
        analysisFailureMessage = nil
    }

    func evaluateHealth(
        examinationId: String,
        status: StatusType?,
        hasFOVData: Bool,
        isTracked: Bool
    ) {
        guard !hasAnalysisFailed else { return }

        if isTracked, status == .NOTSTARTED {
            markFailed(message: AppTextExamProgress.analysisFailedDefault, examinationId: examinationId)
            return
        }

        let isWaitingForAnalysis = status == .INPROGRESS
        let isWaitingForFOVs = status == .NEEDVALIDATION && !hasFOVData
        guard isWaitingForAnalysis || isWaitingForFOVs else { return }

        let startedAt = analysisTrackingStartedAt ?? Date()
        let progressAnchor = lastProgressChangeAt ?? startedAt
        let now = Date()

        if now.timeIntervalSince(startedAt) > analysisMaxDuration {
            markFailed(message: AppTextExamProgress.analysisStalledMessage, examinationId: examinationId)
            return
        }

        let stallLimit = isWaitingForFOVs ? fovLoadStallTimeout : analysisStallTimeout
        if now.timeIntervalSince(progressAnchor) > stallLimit {
            markFailed(message: AppTextExamProgress.analysisStalledMessage, examinationId: examinationId)
        }
    }

    private func loadCachedProgress(examinationId: String) async {
        guard let cached = await progressInteractor.fetchProgress(examinationId: examinationId) else {
            return
        }
        applyProgressUpdate(cached, examinationId: examinationId)
    }

    deinit {
        if let progressObserver {
            NotificationCenter.default.removeObserver(progressObserver)
        }
        trackingTask?.cancel()
    }
}
