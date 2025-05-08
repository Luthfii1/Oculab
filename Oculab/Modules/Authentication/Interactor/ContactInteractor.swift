//
//  ContactInteractor.swift
//  Oculab
//
//  Created by Bunga Prameswari on 07/05/25.
//

import Foundation
import SwiftData

struct ContactResponse {
    var id: String
    var whatsappLink: String
}

class ContactInteractor {
    let urlGetWhatsappLink = API.BE + "/contact/get-whatsapp-link/"

    func getWhatsappLinkById(contactId: String) async throws -> ContactResponse {
        let urlString = "\(urlGetWhatsappLink)\(contactId)"

        let response: APIResponse<Contact> = try await NetworkHelper.shared.get(
            urlString: urlString
        )

        return ContactResponse(
            id: response.data.id,
            whatsappLink: response.data.whatsappLink
        )
    }
}
