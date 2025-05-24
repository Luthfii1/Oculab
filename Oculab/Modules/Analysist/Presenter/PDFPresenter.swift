//
//  PDFPresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 21/05/25.
//

import Foundation

class PDFPresenter: ObservableObject {
    private var interactor = PDFInteractor()
    
    @Published var description: String?
    @Published var isError: Bool = false
    @Published var data: PDFEntity?
    
    @MainActor
    func getPdfData(examinationId: String) async {
        do {
            let response = try await interactor.getPDFData(examinationId: examinationId)
            self.data = response
        } catch {
            switch error {
            case let NetworkError.apiError(apiResponse):
                handleErrorState(isError: true, errorData: apiResponse.data)
            case let NetworkError.networkError(message):
                handleErrorState(
                    isError: true,
                    errorData: ApiErrorData(errorType: "NETWORK_ERROR", description: message)
                )
            default:
                handleErrorState(
                    isError: true,
                    errorData: ApiErrorData(errorType: "UNKNOW_ERROR", description: error.localizedDescription)
                )
            }
        }
    }
    
    private func handleErrorState(isError: Bool, errorData: ApiErrorData? = nil) {
        DispatchQueue.main.async {
            if isError, let errorData = errorData {
                print("Error type: \(errorData.errorType)")
                print("Error description: \(errorData.description)")
                self.description = errorData.description
            }
            self.isError = isError
        }
    }
    
    func navigateToPreviousScreen() {
        Router.shared.navigateBack()
    }
}
