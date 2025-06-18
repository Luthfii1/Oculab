//
//  NetworkPut.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 08/06/25.
//

import Foundation

extension NetworkHelper {
    func put<T: Encodable, U: Decodable>(urlString: String, body: T) async throws -> APIResponse<U> {
        guard let jsonData = try? JSONEncoder().encode(body),
              let request = createRequest(urlString: urlString, httpMethod: "PUT", body: jsonData)
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
