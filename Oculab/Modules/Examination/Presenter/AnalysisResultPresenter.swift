//
//  AnalysisResultPresenter.swift
//  Oculab
//
//  Created by Risa on 18/10/24.
//

import Foundation
import SwiftUI

class AnalysisResultPresenter: ObservableObject {
    // MARK: - Dependencies
    private let interactor: AnalysisResultInteractor
    private let progressInteractor = AnalysisProgressInteractor()

    // MARK: - Task Handles
    private var fetchTask: Task<Void, Never>?
    private var trackingTask: Task<Void, Never>?
    private var progressObserver: NSObjectProtocol?
    private var trackedExaminationId: String?
    private var analysisTrackingStartedAt: Date?
    private var lastProgressChangeAt: Date?
    private let minimumProgressDisplay: TimeInterval = 1.2
    private let analysisStallTimeout: TimeInterval = 10 * 60
    private let analysisMaxDuration: TimeInterval = 30 * 60
    private let fovLoadStallTimeout: TimeInterval = 5 * 60

    init(interactor: AnalysisResultInteractor = AnalysisResultInteractor()) {
        self.interactor = interactor
    }

    // MARK: - Published Properties
    @Published var examinationResult: ExaminationResultData?
    @Published var errorMessage: String?
    @Published var confidenceLevel: ConfidenceLevel = .unpredicted
    @Published var resultQuantity: Int = 0
    @Published var groupedFOVs: FOVGrouping?
    @Published var isLoading = false
    @Published var analysisProgress: Int = 0
    @Published var analysisStatusMessage: String = AppTextExamProgress.analyzingTitle
    @Published var analysisFailureMessage: String?

    // MARK: - UI State Properties
    @Published var selectedTBGrade: String = AppValue.empty {
        didSet {
            // Drop SCANTY-specific count when staff switches to a different grade,
            // so submitExpertResult doesn't ship a stale value alongside e.g. PLUS3.
            if selectedTBGrade != GradingType.SCANTY.rawValue {
                numOfBTA = AppValue.empty
            }
        }
    }
    @Published var numOfBTA: String = AppValue.empty
    @Published var inspectorNotes: String = AppValue.empty
    @Published private var currentStep: Int = 3
    @Published var isVerifPopUpVisible = false
    @Published var isLeavePopUpVisible = false
    @Published var buttonTitle: String = AppTextExamProgress.buttonSaveResult
    @Published var isAllFOVsVerified: Bool = false
    @Published var startTime: Date?

    // MARK: - Computed Properties
    var systemGrading: GradingType {
        examinationResult?.systemGrading ?? .unknown
    }

    var systemConfidenceLevel: ConfidenceLevel {
        ConfidenceLevel.classify(
            aggregatedConfidence: examinationResult?.confidenceLevelAggregated ?? 0.0
        )
    }

    let columnsFOVAlbum = [
        GridItem(.adaptive(minimum: AppConstants.fovGridMinItemSize))
    ]

    var validatedBacteriaTotalCount: Int {
        guard let groupedFOVs else {
            return examinationResult?.bacteriaTotalCount ?? 0
        }
        let allFOVs = groupedFOVs.bta0 + groupedFOVs.bta1to9 + groupedFOVs.btaabove9
        guard !allFOVs.isEmpty else {
            return examinationResult?.bacteriaTotalCount ?? 0
        }
        return allFOVs.reduce(0) { $0 + $1.effectiveBacteriaCount }
    }

    var systemGradingCount: Int {
        switch systemGrading {
        case .NEGATIVE:
            return 0 // NEGATIVE cases don't show count
        case .Plus2:
            return groupedFOVs?.bta1to9.count ?? 0
        case .Plus3:
            return groupedFOVs?.btaabove9.count ?? 0
        default:
            return validatedBacteriaTotalCount
        }
    }

    func selectedFOVs(for fovGroup: FOVType) -> [FOVData] {
        guard let groupedFOVs = groupedFOVs else { return [] }

        switch fovGroup {
        case .BTA0:
            return groupedFOVs.bta0
        case .BTA1TO9:
            return groupedFOVs.bta1to9
        case .BTAABOVE9:
            return groupedFOVs.btaabove9
        }
    }

    var availableFOVTypes: [FOVType] {
        return [.BTA0, .BTA1TO9, .BTAABOVE9]
    }

    var hasFOVData: Bool {
        guard let groupedFOVs else { return false }
        return !groupedFOVs.bta0.isEmpty
            || !groupedFOVs.bta1to9.isEmpty
            || !groupedFOVs.btaabove9.isEmpty
    }

    var previewFOVs: [FOVData] {
        guard let groupedFOVs else { return [] }
        let all = groupedFOVs.bta0 + groupedFOVs.bta1to9 + groupedFOVs.btaabove9
        return Array(all.sorted { $0.order < $1.order }.prefix(4))
    }

    var hasAnalysisFailed: Bool {
        analysisFailureMessage != nil
    }

    var analysisRecoveryHint: String {
        if analysisFailureMessage == AppTextExamProgress.analysisStalledMessage {
            return AppTextExamProgress.analysisStalledHint
        }
        return AppTextExamProgress.analysisFailedHint
    }

    var shouldShowResultsUI: Bool {
        guard let examination = examinationResult, !hasAnalysisFailed else { return false }
        return examination.statusExamination == .NEEDVALIDATION
            || examination.statusExamination == .FINISHED
    }

    var shouldShowAnalyzingUI: Bool {
        if hasAnalysisFailed {
            return true
        }

        guard let examination = examinationResult else {
            return isLoading
        }

        switch examination.statusExamination {
        case .INPROGRESS:
            return true
        case .NEEDVALIDATION:
            return !hasFOVData
        case .NOTSTARTED:
            return AnalysisTrackingStore.isTracked(examination.examinationId)
        default:
            return false
        }
    }

    private var shouldKeepPolling: Bool {
        if hasAnalysisFailed {
            return false
        }

        guard let examination = examinationResult else { return true }

        if examination.statusExamination == .INPROGRESS {
            return true
        }

        if examination.statusExamination == .NEEDVALIDATION, !hasFOVData {
            return true
        }

        return false
    }

    // MARK: - Helper Methods
    func fovCount(for fovType: FOVType) -> Int? {
        guard let groupedFOVs = groupedFOVs else { return nil }

        switch fovType {
        case .BTA0:
            return groupedFOVs.bta0.isEmpty ? nil : groupedFOVs.bta0.count
        case .BTA1TO9:
            return groupedFOVs.bta1to9.isEmpty ? nil : groupedFOVs.bta1to9.count
        case .BTAABOVE9:
            return groupedFOVs.btaabove9.isEmpty ? nil : groupedFOVs.btaabove9.count
        }
    }
}

// MARK: - Navigation Methods
extension AnalysisResultPresenter {
    func popToRoot() {
        Router.shared.popToRoot()
    }

    @MainActor
    func handleHeaderClose(examinationId: String) {
        if shouldShowResultsUI && !shouldShowAnalyzingUI {
            exitFromFlow(examinationId: examinationId)
        } else if hasAnalysisFailed {
            exitFromFlow(examinationId: examinationId)
        } else {
            isLeavePopUpVisible = true
        }
    }

    @MainActor
    func exitFromFlow(examinationId: String) {
        AnalysisResultSessionStore.shared.unregister(examinationId: examinationId)
        AnalysisTrackingStore.untrack(examinationId: examinationId)
        stopExaminationStatusPolling()
        resetState()
        popToRoot()
    }

    func navigateToAlbum(fovGroup: FOVType) {
        let examId = examinationResult?.examinationId ?? AppValue.empty
        Router.shared.navigateTo(.photoAlbum(fovGroup: fovGroup, examId: examId))
    }

    func navigateToDetailed(
        fovData: FOVData,
        order: Int,
        total: Int,
        examId: String?,
        fovGroup: FOVType
    ) {
        let slideId = examinationResult?.slideId ?? AppValue.empty
        let fovs = selectedFOVs(for: fovGroup)
        let resolvedIndex = fovs.firstIndex(where: { $0.id == fovData.id }) ?? order
        Router.shared.navigateTo(.detailedPhoto(
            slideId: slideId,
            fovs: fovs.isEmpty ? [fovData] : fovs,
            currentIndex: min(max(resolvedIndex, 0), max(fovs.count - 1, 0)),
            examId: examId
        ))
    }

    func navigateToPDFView() {
        guard let examId = examinationResult?.examinationId else { return }
        Router.shared.navigateTo(.pdf(examinationId: examId))
    }
}

// MARK: - Time Tracking Methods
extension AnalysisResultPresenter {
    func setStartTime() {
        startTime = Date()
        Logger.info("Start time set", category: .examination)
    }

    @MainActor
    func submitTrackingDuration(examinationId: String) async {
        guard let validStartTime = startTime else {
            Logger.warning("startTime is nil, cannot submit tracking duration", category: .examination)
            return
        }

        do {
            Logger.info("Submitting tracking duration from \(validStartTime) to \(Date())", category: .examination)

            _ = try await interactor.submitTrackingDuration(
                examId: examinationId,
                body: TrackingDurationRequest(
                    startTimestamp: DateFormatterHelper.shared.formatToISO8601(validStartTime),
                    endTimestamp: DateFormatterHelper.shared.formatToISO8601(Date())
                )
            )

            Logger.info("Tracking duration submitted successfully", category: .examination)

        } catch {
            errorMessage = ErrorHandler.shared.handleError(error, context: .examination)
        }
    }
}

// MARK: - Data Management Methods
extension AnalysisResultPresenter {
    @MainActor
    func fetchData(examinationId: String, silent: Bool = false) async {
        if !silent {
            defer { isLoading = false }
            isLoading = true
        }

        do {
            examinationResult = try await interactor.fetchData(examId: examinationId)

            if examinationResult?.statusExamination != .INPROGRESS {
                await loadFOVData(examinationId: examinationId, silent: silent)
            }

            markAnalysisReadyIfNeeded(examinationId: examinationId)
            evaluateAnalysisHealth(examinationId: examinationId)
        } catch {
            if !silent {
                errorMessage = ErrorHandler.shared.handleError(error, context: .examination)
            }
        }
    }

    @MainActor
    func refreshFOVData(examinationId: String) async {
        await loadFOVData(examinationId: examinationId, silent: true)
    }

    @MainActor
    func refreshValidationData(examinationId: String) async {
        await fetchData(examinationId: examinationId, silent: true)
    }

    @MainActor
    private func loadFOVData(examinationId: String, silent: Bool) async {
        do {
            groupedFOVs = try await interactor.fetchFOVData(examId: examinationId)
            checkIsAllFOVsVerified()
            syncStaffBacteriaCountFromValidation()

            if hasFOVData {
                analysisProgress = max(analysisProgress, 100)
                markAnalysisReadyIfNeeded(examinationId: examinationId)
            }
        } catch {
            Logger.error("Failed to load FOV data: \(error)", category: .examination)
            if !silent, groupedFOVs == nil {
                errorMessage = ErrorHandler.shared.handleError(error, context: .examination)
            }
        }
    }

    @MainActor
    func refreshExaminationStatus(examinationId: String) async {
        await fetchData(examinationId: examinationId, silent: true)
    }

    @MainActor
    private func markAnalysisReadyIfNeeded(examinationId: String) {
        guard examinationResult?.statusExamination == .NEEDVALIDATION, hasFOVData else { return }
        analysisProgress = max(analysisProgress, 100)
        AnalysisTrackingStore.untrack(examinationId: examinationId)
    }

    @MainActor
    func beginExaminationTracking(examinationId: String) {
        guard trackedExaminationId != examinationId else { return }

        stopExaminationStatusPolling()
        trackedExaminationId = examinationId
        let now = Date()
        analysisTrackingStartedAt = now
        lastProgressChangeAt = now
        startRealtimeTracking(examinationId: examinationId)

        trackingTask = Task {
            await loadCachedProgress(examinationId: examinationId)

            while !Task.isCancelled {
                if shouldKeepPolling {
                    await refreshExaminationStatus(examinationId: examinationId)
                    if let cached = await progressInteractor.fetchProgress(examinationId: examinationId) {
                        applyProgressUpdate(cached, examinationId: examinationId)
                    }
                    evaluateAnalysisHealth(examinationId: examinationId)
                } else if !shouldShowAnalyzingUI {
                    break
                }

                let pollInterval: UInt64 = hasFOVData ? 15_000_000_000 : 5_000_000_000
                try? await Task.sleep(nanoseconds: pollInterval)
                guard !Task.isCancelled else { break }
            }
        }
    }

    @MainActor
    func startExaminationStatusPolling(examinationId: String) {
        beginExaminationTracking(examinationId: examinationId)
    }

    @MainActor
    func stopExaminationStatusPolling() {
        trackingTask?.cancel()
        trackingTask = nil
        stopRealtimeTracking()
        trackedExaminationId = nil
        analysisTrackingStartedAt = nil
    }

    @MainActor
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
                  update.examId.lowercased() == examinationId.lowercased() else {
                return
            }

            Task { @MainActor in
                self.applyProgressUpdate(update, examinationId: examinationId)
                if update.isFailed {
                    return
                }
                if update.isReadyForValidation {
                    await self.refreshExaminationStatus(examinationId: examinationId)
                    await self.loadFOVData(examinationId: examinationId, silent: true)
                }
            }
        }
    }

    @MainActor
    func stopRealtimeTracking() {
        if let progressObserver {
            NotificationCenter.default.removeObserver(progressObserver)
            self.progressObserver = nil
        }
        // Socket stays connected while AnalysisTrackingStore still tracks the exam
        // (e.g. user left progress screen but analysis runs in background).
    }

    @MainActor
    private func loadCachedProgress(examinationId: String) async {
        guard let cached = await progressInteractor.fetchProgress(examinationId: examinationId) else {
            return
        }
        applyProgressUpdate(cached, examinationId: examinationId)
    }

    @MainActor
    private func applyProgressUpdate(_ update: AnalysisProgressUpdate, examinationId: String) {
        if update.isFailed {
            markAnalysisFailed(message: update.message, examinationId: examinationId)
            return
        }

        if update.progress != analysisProgress {
            lastProgressChangeAt = Date()
        }

        analysisProgress = update.progress
        if let message = update.message, !message.isEmpty {
            analysisStatusMessage = message
        }
    }

    @MainActor
    private func evaluateAnalysisHealth(examinationId: String) {
        guard !hasAnalysisFailed, let examination = examinationResult else { return }

        if AnalysisTrackingStore.isTracked(examinationId),
           examination.statusExamination == .NOTSTARTED {
            markAnalysisFailed(
                message: AppTextExamProgress.analysisFailedDefault,
                examinationId: examinationId
            )
            return
        }

        let isWaitingForAnalysis = examination.statusExamination == .INPROGRESS
        let isWaitingForFOVs = examination.statusExamination == .NEEDVALIDATION && !hasFOVData
        guard isWaitingForAnalysis || isWaitingForFOVs else { return }

        let startedAt = analysisTrackingStartedAt ?? Date()
        let progressAnchor = lastProgressChangeAt ?? startedAt
        let elapsed = Date().timeIntervalSince(startedAt)
        let sinceProgressChange = Date().timeIntervalSince(progressAnchor)
        let stallTimeout = isWaitingForFOVs ? fovLoadStallTimeout : analysisStallTimeout

        if elapsed >= analysisMaxDuration || sinceProgressChange >= stallTimeout {
            markAnalysisFailed(
                message: AppTextExamProgress.analysisStalledMessage,
                examinationId: examinationId
            )
        }
    }

    @MainActor
    func markAnalysisFailed(message: String?, examinationId: String) {
        if let message, !message.isEmpty {
            analysisFailureMessage = message
        } else if let statusMessage = analysisStatusMessage.isEmpty ? nil : analysisStatusMessage,
                  statusMessage.localizedCaseInsensitiveContains("fail")
                    || statusMessage.localizedCaseInsensitiveContains("gagal") {
            analysisFailureMessage = statusMessage
        } else {
            analysisFailureMessage = AppTextExamProgress.analysisFailedDefault
        }

        analysisProgress = 0
        AnalysisTrackingStore.untrack(examinationId: examinationId)
        AnalysisRealtimeService.shared.unsubscribe(from: examinationId)
        trackingTask?.cancel()
        trackingTask = nil
        stopRealtimeTracking()
    }

    @MainActor
    func retryAnalysis(examinationId: String) async {
        let patientId = examinationResult?.patientId
        analysisFailureMessage = nil
        stopExaminationStatusPolling()
        AnalysisTrackingStore.untrack(examinationId: examinationId)
        AnalysisRealtimeService.shared.unsubscribe(from: examinationId)
        AnalysisResultSessionStore.shared.unregister(examinationId: examinationId)
        resetState()

        if let patientId, !patientId.isEmpty {
            Router.shared.popToRoot()
            Router.shared.navigateTo(.examDetail(examId: examinationId, patientId: patientId))
            return
        }

        Router.shared.popToRoot()
    }

    @MainActor
    func getStatusExamination(examinationId: String) async {
        await refreshExaminationStatus(examinationId: examinationId)
    }
}

// MARK: - Expert Result Submission Methods
extension AnalysisResultPresenter {
    @MainActor
    func submitExpertResult(examinationId: String) async {
        do {
            let validGrading = GradingType(rawValue: selectedTBGrade)
                ?? GradingType.fromAPIValue(selectedTBGrade)
            guard validGrading != .unknown else {
                throw NetworkError.networkError("Error: Invalid TB Grade", endpoint: "submitExpertResult")
            }

            let bacteriaCount = Int(numOfBTA) ?? 0

            _ = try await interactor.submitExpertResult(
                examId: examinationId,
                expertResult: ExpertExamResult(
                    finalGrading: validGrading,
                    bacteriaTotalCount: bacteriaCount,
                    notes: inspectorNotes
                )
            )

            isVerifPopUpVisible = false
            Router.shared.popToRoot()
        } catch {
            errorMessage = ErrorHandler.shared.handleError(error, context: .examination)
        }
    }

    func isEnableToSubmit() -> Bool {
        isAllFOVsVerified && isValidGradingSelection()
    }

    func isPrimaryActionEnabled() -> Bool {
        if !isAllFOVsVerified {
            return hasFOVData
        }
        return isValidGradingSelection()
    }

    @MainActor
    func handlePrimaryValidationAction() {
        if isAllFOVsVerified {
            isVerifPopUpVisible = true
        } else {
            navigateToFirstUnverifiedAlbum()
        }
    }

    func navigateToFirstUnverifiedAlbum() {
        for fovType in availableFOVTypes {
            let fovs = selectedFOVs(for: fovType)
            guard !fovs.isEmpty, fovs.contains(where: { !$0.verified }) else { continue }
            navigateToAlbum(fovGroup: fovType)
            return
        }
    }

    private func isValidGradingSelection() -> Bool {
        guard selectedTBGrade != AppValue.empty else { return false }

        // For SCANTY grade, require bacteria count
        if selectedTBGrade == GradingType.SCANTY.rawValue {
            return !numOfBTA.isEmpty && Int(numOfBTA) != nil
        }

        return true
    }
}

// MARK: - FOV Verification Methods
extension AnalysisResultPresenter {
    func checkIsAllFOVsVerified() {
        let allVerified: Bool = {
            guard groupedFOVs != nil else { return false }
            return availableFOVTypes.allSatisfy { fovType in
                selectedFOVs(for: fovType).allSatisfy { $0.verified }
            }
        }()

        isAllFOVsVerified = allVerified
        buttonTitle = allVerified ? AppTextExamProgress.buttonSaveResult : AppTextExamProgress.buttonVerifyAllFOVs
    }

    func syncStaffBacteriaCountFromValidation() {
        guard hasFOVData else { return }
        let latestCount = validatedBacteriaTotalCount
        guard latestCount > 0 else { return }

        if numOfBTA.isEmpty {
            numOfBTA = String(latestCount)
        }
    }
}

// MARK: - State Reset
extension AnalysisResultPresenter {
    @MainActor
    func resetState() {
        fetchTask?.cancel()
        fetchTask = nil
        stopExaminationStatusPolling()
        analysisProgress = 0
        analysisStatusMessage = AppTextExamProgress.analyzingTitle
        analysisFailureMessage = nil
        examinationResult = nil
        errorMessage = nil
        confidenceLevel = .unpredicted
        resultQuantity = 0
        groupedFOVs = nil
        isLoading = false
        selectedTBGrade = AppValue.empty
        numOfBTA = AppValue.empty
        inspectorNotes = AppValue.empty
        isVerifPopUpVisible = false
        isLeavePopUpVisible = false
        buttonTitle = AppTextExamProgress.buttonSaveResult
        isAllFOVsVerified = false
        startTime = nil
        analysisTrackingStartedAt = nil
        lastProgressChangeAt = nil
    }
}
