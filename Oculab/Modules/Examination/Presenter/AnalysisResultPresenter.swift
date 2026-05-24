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

    // MARK: - Task Handles
    private var fetchTask: Task<Void, Never>?
    private var trackingTask: Task<Void, Never>?

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
    func fetchData(examinationId: String) async {
        defer { isLoading = false }
        isLoading = true

        do {
            examinationResult = try await interactor.fetchData(examId: examinationId)

            groupedFOVs = try await interactor.fetchFOVData(examId: examinationId)
            checkIsAllFOVsVerified()
        } catch {
            errorMessage = ErrorHandler.shared.handleError(error, context: .examination)
        }
    }

    @MainActor
    func getStatusExamination(examinationId: String) async {
        await fetchData(examinationId: examinationId)
        if examinationResult?.statusExamination == .FINISHED {
            Router.shared.navigateBack()
        }
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
        trackingTask?.cancel()
        trackingTask = nil
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
