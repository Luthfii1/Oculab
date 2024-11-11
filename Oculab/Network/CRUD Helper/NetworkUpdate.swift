//
//  NetworkUpdate.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 22/10/24.
//

import Foundation

extension NetworkHelper {
    func update<T: Encodable, U: Decodable>(
        urlString: String,
        body: T,
        completion: @escaping (Result<APIResponse<U>, APIResponse<ApiErrorData>>) -> Void
    ) {
        guard let jsonData = try? JSONEncoder().encode(body),
              let request = createRequest(urlString: urlString, httpMethod: "PUT", body: jsonData)
        else {
            completion(.failure(createErrorSystem(
                errorType: "InvalidRequest",
                errorMessage: "Error encoding request body"
            )))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            self.handleResponse(data, response, error, completion: completion)
        }.resume()
    }
}
