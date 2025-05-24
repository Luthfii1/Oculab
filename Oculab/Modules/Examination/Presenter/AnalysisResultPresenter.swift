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
    @Published var isWSIImageVisible: Bool = false
    @Published var buttonTitle: String = "Simpan Hasil Pemeriksaan"
    @Published var isAllFOVsVerified: Bool = false

    func popToRoot() {
        Router.shared.popToRoot()
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

    @MainActor
    func getStatusExamination(examinationId: String) async {
        await fetchData(examinationId: examinationId)
        if examinationResult?.statusExamination == .FINISHED {
            Router.shared.navigateBack()
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
    
    func isEnableToSubmit() -> Bool {
        if !isAllFOVsVerified {
            return false
        }
        
        // check if the interpretation already chosen from user
        if selectedTBGrade == GradingType.SCANTY.rawValue {
            return !numOfBTA.isEmpty && Int(numOfBTA) != nil
        } else {
            return selectedTBGrade != ""
        }
    }
    
    func navigateToPDFView() {
        Router.shared.navigateTo(.pdf)
    }
    
    func checkIsAllFOVsVerified() {
        guard let groupedFOVs = groupedFOVs else {
            self.isAllFOVsVerified = false
            self.buttonTitle = "Verikasi Semua Lapang Pandang"
            return
        }
        
        // Check each group
        let bta0Verified = groupedFOVs.bta0.allSatisfy { $0.verified }
        let bta1to9Verified = groupedFOVs.bta1to9.allSatisfy { $0.verified }
        let btaAbove9Verified = groupedFOVs.btaabove9.allSatisfy { $0.verified }
        
        // All groups must be verified
        let isAllVerified = bta0Verified && bta1to9Verified && btaAbove9Verified
        self.isAllFOVsVerified = isAllVerified
        
        // Update button title based on verification status
        if isAllVerified {
            self.buttonTitle = "Simpan Hasil Pemeriksaan"
        } else {
            self.buttonTitle = "Verikasi Semua Lapang Pandang"
        }
    }
}
