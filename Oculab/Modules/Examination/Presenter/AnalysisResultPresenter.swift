//
//  AnalysisResultPresenter.swift
//  Oculab
//
//  Created by Risa on 18/10/24.
//

import Foundation

class AnalysisResultPresenter: ObservableObject {
    var view: AnalysisResultView?
    var interactor: AnalysisResultInteractor? = AnalysisResultInteractor()

    @Published var examinationResult: ExaminationResultData?
    @Published var errorMessage: String?
    @Published var confidenceLevel: ConfidenceLevel = .unpredicted
    @Published var resultQuantity: Int = 0
    @Published var groupedFOVs: FOVGrouping?

    // MARK: State for view

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

    func popToRoot() {
        Router.shared.popToRoot()
    }

    func setStartTime() {
        startTime = Date()
        print(startTime)
    }

    func formatDateToISO8601(date: Date) -> String {
        let formatter = DateFormatter()

        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"

        formatter.timeZone = TimeZone(identifier: "UTC")

        formatter.locale = Locale(identifier: "en_US_POSIX")

        return formatter.string(from: date)
    }

    func submitTrackingDuration(examinationId: String) async {
        guard let validStartTime = startTime else {
            print("Error: startTime is nil, cannot submit tracking duration.")
            return
        }

        do {
            print("\(validStartTime)")
            print("\(Date())")
            _ = try await interactor?.submitTrackingDuration(
                examId: examinationId,
                body: TrackingDurationRequest(
                    startTimestamp: formatDateToISO8601(date: validStartTime),
                    endTimestamp: formatDateToISO8601(date: Date())
                )
            )

            print("Tracking duration submitted successfully.")

        } catch {
            errorMessage = ErrorHandler.shared.handleError(error, context: .examination)
        }
    }

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

    @MainActor
    func fetchData(examinationId: String) async {
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

    func navigateToPDFView() {
        guard let examId = examinationResult?.examinationId else { return }
        Router.shared.navigateTo(.pdf(examinationId: examId))
    }

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
