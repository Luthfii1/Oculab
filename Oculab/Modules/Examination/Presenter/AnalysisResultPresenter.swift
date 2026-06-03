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

    // MARK: - UI State Properties
    @Published var selectedTBGrade: String = AppValue.empty
    @Published var numOfBTA: String = AppValue.empty
    @Published var inspectorNotes: String = AppValue.empty
    @Published private var currentStep: Int = 3
    @Published var isVerifPopUpVisible = false
    @Published var isLeavePopUpVisible = false
    @Published var isWSIImageVisible: Bool = false
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

    var systemGradingCount: Int {
        switch systemGrading {
        case .NEGATIVE:
            return 0 // NEGATIVE cases don't show count
        case .Plus2:
            return groupedFOVs?.bta1to9.count ?? 0
        case .Plus3:
            return groupedFOVs?.btaabove9.count ?? 0
        default:
            return examinationResult?.bacteriaTotalCount ?? 0
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

    func navigateToAlbum(fovGroup: FOVType) {
        let examId = examinationResult?.examinationId ?? AppValue.empty
        Router.shared.navigateTo(.photoAlbum(fovGroup: fovGroup, examId: examId))
    }

    func navigateToDetailed(fovData: FOVData, order: Int, total: Int, examId: String?) {
        let slideId = examinationResult?.slideId ?? AppValue.empty
        Router.shared.navigateTo(.detailedPhoto(
            slideId: slideId,
            fovData: fovData,
            order: order,
            total: total,
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
                groupedFOVs = try await interactor.fetchFOVData(examId: examinationId)
                checkIsAllFOVsVerified()
            }
        } catch {
            if !silent {
                errorMessage = ErrorHandler.shared.handleError(error, context: .examination)
            }
        }
    }

    @MainActor
    func refreshExaminationStatus(examinationId: String) async {
        await fetchData(examinationId: examinationId, silent: true)
        if examinationResult?.statusExamination == .FINISHED {
            Router.shared.navigateBack()
        }
    }

    @MainActor
    func startExaminationStatusPolling(examinationId: String) {
        stopExaminationStatusPolling()
        trackedExaminationId = examinationId
        startRealtimeTracking(examinationId: examinationId)

        trackingTask = Task {
            await loadCachedProgress(examinationId: examinationId)

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                guard !Task.isCancelled else { break }
                await refreshExaminationStatus(examinationId: examinationId)
                if let cached = await progressInteractor.fetchProgress(examinationId: examinationId) {
                    applyProgressUpdate(cached)
                }
                guard examinationResult?.statusExamination == .INPROGRESS else { break }
            }
        }
    }

    @MainActor
    func stopExaminationStatusPolling() {
        trackingTask?.cancel()
        trackingTask = nil
        stopRealtimeTracking()
        trackedExaminationId = nil
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
                self.applyProgressUpdate(update)
                if update.isReadyForValidation {
                    await self.refreshExaminationStatus(examinationId: examinationId)
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
        applyProgressUpdate(cached)
    }

    @MainActor
    private func applyProgressUpdate(_ update: AnalysisProgressUpdate) {
        analysisProgress = update.progress
        if let message = update.message, !message.isEmpty {
            analysisStatusMessage = message
        }
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
            guard let validGrading = GradingType(rawValue: selectedTBGrade) else {
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
        return isValidGradingSelection()
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
        isWSIImageVisible = false
        buttonTitle = AppTextExamProgress.buttonSaveResult
        isAllFOVsVerified = false
        startTime = nil
    }
}
