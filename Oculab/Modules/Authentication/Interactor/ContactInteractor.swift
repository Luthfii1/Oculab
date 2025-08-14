//
//  ContactInteractor.swift
//  Oculab
//
//  Created by Bunga Prameswari on 07/05/25.
//

import Foundation
import SwiftData

struct ContactResponse: Decodable {
    var id: String
    var whatsappLink: String
}

class ContactInteractor {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = AlamofireNetworkService()) {
        self.networkService = networkService
    }
    
    let urlGetWhatsappLink = API.BE + "/contact/get-whatsapp-link/"

    func getWhatsappLinkById() async throws -> ContactResponse {
        let urlString = "\(urlGetWhatsappLink)"

        let response: APIResponse<ContactResponse> = try await networkService.get(
            urlString: urlString,
            headers: nil
        )

        return ContactResponse(
            id: response.data.id,
            whatsappLink: response.data.whatsappLink
        )
    }
}
