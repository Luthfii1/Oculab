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

    func fetchData(examinationId: String) {
        interactor?.fetchData(examId: examinationId) { [weak self] result in
            switch result {
            case let .success(examination):
                self?.examinationResult = examination
            case let .failure(error):
                print("error: ", error.localizedDescription)
            }
        }

        interactor?.fetchFOVData(examId: examinationId) { [weak self] result in
            switch result {
            case let .success(fov):
                self?.groupedFOVs = fov
            case let .failure(error):
                print("error: ", error.localizedDescription)
            }
        }
    }
}
