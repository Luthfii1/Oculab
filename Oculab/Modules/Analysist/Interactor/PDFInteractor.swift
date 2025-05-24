//
//  PDFInteractor.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 24/05/25.
//

import Foundation

class PDFInteractor {
    private var endpoint = API.BE

    func getPDFData(examinationId: String) async throws -> PDFEntity {
        let response: APIResponse<PDFEntity> = try await NetworkHelper.shared.get(
            urlString: endpoint + "/pdf/get-data-for-pdf-by-id/" + examinationId
        )
        
        return response.data
    }
}
