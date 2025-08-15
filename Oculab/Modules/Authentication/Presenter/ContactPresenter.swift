//
//  ContactPresenter.swift
//  Oculab
//
//  Created by Bunga Prameswari on 07/05/25.
//

import SwiftUI

class ContactPresenter: ObservableObject {
    @Published var contactData: ContactResponse = .init(
        id: AppValue.empty,
        whatsappLink: AppValue.empty
    )

    private let interactor: ContactInteractor

    init(interactor: ContactInteractor) {
        self.interactor = interactor
    }

    @MainActor
    func fetchData() async {
        do {
            let contactResponse = try await interactor.getWhatsappLinkById()

            contactData = contactResponse
        } catch {
            _ = ErrorHandler.shared.handleError(error)
        }
    }
    
    func directToWhatsapp() async {
        await fetchData()
        if let url = URL(string: contactData.whatsappLink) {
            await MainActor.run {
                UIApplication.shared.open(url)
            }
        }
    }
}
