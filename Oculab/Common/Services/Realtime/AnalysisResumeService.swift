//
//  AnalysisResumeService.swift
//  Oculab
//

import Foundation

@MainActor
final class AnalysisResumeService {
    static let shared = AnalysisResumeService()

    private let progressInteractor = AnalysisProgressInteractor()
    private var didAutoResumeThisSession = false

    private init() {}

    /// Cold start: reconnect sockets, hydrate Redis progress, optionally reopen analyzing screen.
    func restoreOnLaunch() async {
        await reconnectTrackedAnalyses()
        await pruneCompletedTracks()

        guard !didAutoResumeThisSession,
              let resumeId = AnalysisTrackingStore.pendingResumeExaminationId,
              AnalysisTrackingStore.isTracked(resumeId)
        else { return }

        didAutoResumeThisSession = true
        try? await Task.sleep(nanoseconds: 600_000_000)
        Router.shared.navigateTo(.analysisResult(examinationId: resumeId))
    }

    /// Foreground: reconnect sockets and refresh cached progress payloads.
    func reconnectOnForeground() async {
        await reconnectTrackedAnalyses()
    }

    // MARK: - Private

    private func reconnectTrackedAnalyses() async {
        let tracked = AnalysisTrackingStore.trackedIds
        guard !tracked.isEmpty else { return }

        for examId in tracked {
            AnalysisRealtimeService.shared.subscribe(to: examId)
            if let progress = await progressInteractor.fetchProgress(examinationId: examId) {
                NotificationCenter.default.post(
                    name: .examinationAnalysisProgress,
                    object: nil,
                    userInfo: ["update": progress]
                )
            }
        }
    }

    private func pruneCompletedTracks() async {
        for examId in AnalysisTrackingStore.trackedIds {
            guard let progress = await progressInteractor.fetchProgress(examinationId: examId) else {
                continue
            }

            let isTerminal = progress.isReadyForValidation
                || progress.status == "completed"
                || progress.isFailed

            guard isTerminal else { continue }

            AnalysisTrackingStore.untrack(examinationId: examId)
            AnalysisRealtimeService.shared.unsubscribe(from: examId)

            if AnalysisTrackingStore.pendingResumeExaminationId?.lowercased() == examId.lowercased() {
                AnalysisTrackingStore.clearPendingResume()
            }
        }
    }
}
