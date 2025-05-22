//
//  NetworkUpdate.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 22/10/24.
//

import Foundation

extension NetworkHelper {
    func update<T: Encodable, U: Decodable>(urlString: String, body: T, headers: [String: String]? = nil) async throws -> APIResponse<U> {
        guard let jsonData = try? JSONEncoder().encode(body),
              var request = createRequest(urlString: urlString, httpMethod: "PUT", body: jsonData)
        else {
            throw NSError(
                domain: "InvalidRequest",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Error encoding request body"]
            )
        }
        
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        return try handleAsyncResponse(data: data, response: response)
    }
}
