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
    @Published var groupedFOVs: [FOVType: [FOV]] = [:]

    func fetchData(examinationId: String) {
        interactor?.fetchData(examinationId: examinationId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case let .success(examinationResult):
                    self?.examinationResult = examinationResult
                    self?.confidenceLevel = ConfidenceLevel
                        .classify(aggregatedConfidence: examinationResult.confidenceLevelAggregated)
                    self?.groupedFOVs = Dictionary(grouping: examinationResult.fov, by: { $0.type })

                    if self?.examinationResult?.systemGrading == .SCANTY || self?.examinationResult?
                        .systemGrading == .Plus1
                    {
                        self?.resultQuantity = examinationResult.bacteriaTotalCount

                    } else if self?.examinationResult?.systemGrading == .Plus2 {
                        self?.resultQuantity = self?.groupedFOVs[.BTA1TO9]?.count ?? 0

                    } else if self?.examinationResult?.systemGrading == .Plus3 {
                        self?.resultQuantity = self?.groupedFOVs[.BTAABOVE9]?.count ?? 0
                    }

                case let .failure(error):
                    self?.errorMessage = "Failed to load examination data: \(error.localizedDescription)"
                }
            }
        }
    }
}
