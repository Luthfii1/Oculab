//
//  NetworkDelete.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 22/10/24.
//

import Foundation

extension NetworkHelper {
    func delete<T: Encodable, U: Decodable>(
        urlString: String,
        body: T?,
        completion: @escaping (Result<APIResponse<U>, APIResponse<ApiErrorData>>) -> Void
    ) {
        var jsonData: Data?
        if let body = body {
            jsonData = try? JSONEncoder().encode(body)
        }

        guard let request = createRequest(urlString: urlString, httpMethod: "DELETE", body: jsonData) else {
            completion(.failure(createErrorSystem(errorType: "InvalidRequest", errorMessage: "Error creating request")))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            self.handleResponse(data, response, error, completion: completion)
        }.resume()
    }
}
