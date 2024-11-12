//
//  NetworkPost.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 22/10/24.
//

import Foundation

extension NetworkHelper {
    func post<T: Encodable, U: Decodable>(urlString: String, body: T) async throws -> APIResponse<U> {
        guard let jsonData = try? JSONEncoder().encode(body),
              let request = createRequest(urlString: urlString, httpMethod: "POST", body: jsonData)
        else {
            throw NSError(
                domain: "InvalidRequest",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Error encoding request body"]
            )
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        return try handleAsyncResponse(data: data, response: response)
    }
}
