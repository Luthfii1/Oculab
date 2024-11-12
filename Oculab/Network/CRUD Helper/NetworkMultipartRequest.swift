//
//  NetworkMultipartRequest.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 12/11/24.
//

import Foundation

extension NetworkHelper {
    func multipart<T: Decodable>(
        urlString: String,
        parameters: [String: Data],
        boundary: String = UUID().uuidString
    ) async throws -> APIResponse<T> {
        guard let request = createMultipartRequest(
            urlString: urlString,
            httpMethod: "POST",
            parameters: parameters,
            boundary: boundary
        ) else {
            throw NetworkError.networkError("Error creating multipart request")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        return try handleAsyncResponse(data: data, response: response)
    }
}
