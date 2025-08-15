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
    @Published var errorMessage: String?
    @Published var data: PDFEntity?
    
    @MainActor
    func getPdfData(examinationId: String) async {
        do {
            let response = try await interactor.getPDFData(examinationId: examinationId)
            self.data = response
        } catch {
            errorMessage = ErrorHandler.shared.handleError(error, context: .examination)
            isError = true
        }
    }
    
    func navigateToPreviousScreen() {
        Router.shared.navigateBack()
    }
}
