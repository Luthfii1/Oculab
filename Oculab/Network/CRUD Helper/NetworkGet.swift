//
//  NetworkGet.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 22/10/24.
//

import Foundation

extension NetworkHelper {
    func get<T: Decodable>(
        urlString: String,
        completion: @escaping (Result<APIResponse<T>, APIResponse<ApiErrorData>>) -> Void
    ) {
        guard let request = createRequest(urlString: urlString, httpMethod: "GET", body: nil) else {
            completion(.failure(createErrorSystem(errorType: "InvalidRequest", errorMessage: "Error creating request")))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            self.handleResponse(data, response, error, completion: completion)
        }.resume()
    }
}
