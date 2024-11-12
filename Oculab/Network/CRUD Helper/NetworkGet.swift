//
//  NetworkGet.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 22/10/24.
//

import Foundation

extension NetworkHelper {
    func get<T: Decodable>(urlString: String) async throws -> APIResponse<T> {
        guard let request = createRequest(urlString: urlString, httpMethod: "GET", body: nil) else {
            throw NSError(
                domain: "InvalidRequest",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Error creating request"]
            )
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        return try handleAsyncResponse(data: data, response: response)
    }
}
