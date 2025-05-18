//
//  NetworkDelete.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 22/10/24.
//

import Foundation

extension NetworkHelper {
    func delete<T: Encodable, U: Decodable>(urlString: String, body: T? = nil, headers: [String: String]? = nil) async throws -> APIResponse<U> {
        var jsonData: Data?
        if let body = body {
            do {
                jsonData = try JSONEncoder().encode(body)
            } catch {
                throw NSError(
                    domain: "EncodingError",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Error encoding request body: \(error.localizedDescription)"
                    ]
                )
            }
        }

        guard var request = createRequest(urlString: urlString, httpMethod: "DELETE", body: jsonData) else {
            throw NSError(
                domain: "InvalidRequest",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Error creating request"]
            )
        }
        
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        return try handleAsyncResponse(data: data, response: response)
    }
}
