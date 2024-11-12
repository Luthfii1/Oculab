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

    @Published var selectedTBGrade: String = ""
    @Published var numOfBTA: String = ""
    @Published var inspectorNotes: String = ""
    @Published private var currentStep: Int = 3
    @Published var isVerifPopUpVisible = false
    @Published var isLeavePopUpVisible = false

    func popToRoot() {
        Router.shared.popToRoot()
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
            }
        } catch {
            // Handle error
            switch error {
            case let NetworkError.apiError(apiResponse):
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")

            case let NetworkError.networkError(message):
                print("Network error: \(message)")

            default:
                print("Unknown error: \(error.localizedDescription)")
            }
        }
    }

    func navigateToAlbum(fovGroup: FOVType) {
        Router.shared.navigateTo(.photoAlbum(fovGroup: fovGroup, examId: examinationResult?.examinationId ?? ""))
    }

    func navigateToDetailed(fovData: FOVData, order: Int, total: Int) {
        Router.shared.navigateTo(.detailedPhoto(
            slideId: examinationResult?.slideId ?? "",
            fovData: fovData,
            order: order,
            total: total
        ))
    }
}
