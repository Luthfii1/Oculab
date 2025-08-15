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
    var view: AnalysisResultView?
    private var interactor: AnalysisResultInteractor? = AnalysisResultInteractor()

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
        Router.shared.navigateTo(.photoAlbum(fovGroup: fovGroup, examId: examinationResult?.examinationId ?? AppValue.empty))
    }

    func navigateToDetailed(fovData: FOVData, order: Int, total: Int, examId: String?) {
        Router.shared.navigateTo(.detailedPhoto(
            slideId: examinationResult?.slideId ?? AppValue.empty,
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
        Logger.info("Start time set: \(String(describing: startTime))", category: .examination)
    }

    func submitTrackingDuration(examinationId: String) async {
        guard let validStartTime = startTime else {
            Logger.warning("startTime is nil, cannot submit tracking duration", category: .examination)
            return
        }

        do {
            Logger.info("Submitting tracking duration from \(validStartTime) to \(Date())", category: .examination)
            
            _ = try await interactor?.submitTrackingDuration(
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
            let result = try await interactor?.fetchData(examId: examinationId)
            if let result {
                examinationResult = result
            }

            let groupedFOVs = try await interactor?.fetchFOVData(examId: examinationId)
            if let groupedFOVs {
                self.groupedFOVs = groupedFOVs
                checkIsAllFOVsVerified()
            }
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
                throw NetworkError.networkError("Error: Invalid TB Grade")
            }

            _ = try await interactor?.submitExpertResult(
                examId: examinationId,
                expertResult: ExpertExamResult(
                    finalGrading: validGrading,
                    bacteriaTotalCount: Int(numOfBTA),
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
        // TODO: Need to discuss is it should check all FOVs Verified or not
//        if !isAllFOVsVerified {
//            return false
//        }

        // check if the interpretation already chosen from user
        if selectedTBGrade == GradingType.SCANTY.rawValue {
            return !numOfBTA.isEmpty && Int(numOfBTA) != nil
        } else {
            return selectedTBGrade != AppValue.empty
        }
    }
}

// MARK: - FOV Verification Methods
extension AnalysisResultPresenter {
    func checkIsAllFOVsVerified() {
        guard let groupedFOVs = groupedFOVs else {
            isAllFOVsVerified = false
            buttonTitle = AppTextExamProgress.buttonVerifyAllFOVs
            return
        }

        // Check each group
        let bta0Verified = groupedFOVs.bta0.allSatisfy { $0.verified }
        let bta1to9Verified = groupedFOVs.bta1to9.allSatisfy { $0.verified }
        let btaAbove9Verified = groupedFOVs.btaabove9.allSatisfy { $0.verified }

        // All groups must be verified
        let isAllVerified = bta0Verified && bta1to9Verified && btaAbove9Verified
        isAllFOVsVerified = isAllVerified

        // Update button title based on verification status
        if isAllVerified {
            buttonTitle = AppTextExamProgress.buttonSaveResult
        } else {
            buttonTitle = AppTextExamProgress.buttonVerifyAllFOVs
        }
    }
}
