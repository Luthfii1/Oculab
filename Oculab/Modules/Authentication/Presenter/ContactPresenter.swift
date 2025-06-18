//
//  ContactPresenter.swift
//  Oculab
//
//  Created by Bunga Prameswari on 07/05/25.
//

import SwiftUI

class ContactPresenter: ObservableObject {
    @Published var contactData: ContactResponse = .init(
        id: "",
        whatsappLink: ""
    )

    private let interactor: ContactInteractor

    init(interactor: ContactInteractor) {
        self.interactor = interactor
    }

    @MainActor
    func fetchData(contactId: String) async {
        do {
            let contactResponse = try await interactor.getWhatsappLinkById(contactId: contactId)

            contactData = contactResponse
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
}
