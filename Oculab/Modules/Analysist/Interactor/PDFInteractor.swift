//
//  PDFInteractor.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 24/05/25.
//

import Foundation

class PDFInteractor {
    private var endpoint = API.BE
    private let networkService: NetworkService

    init(networkService: NetworkService = AlamofireNetworkService()) {
        self.networkService = networkService
    }

    func getPDFData(examinationId: String) async throws -> PDFEntity {
        let response: APIResponse<PDFEntity> = try await networkService.get(
            urlString: endpoint + "/pdf/get-data-for-pdf-by-id/" + examinationId,
            headers: nil
        )
        
        return response.data
    }
}
