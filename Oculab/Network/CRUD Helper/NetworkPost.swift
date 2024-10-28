//
//  NetworkPost.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 22/10/24.
//

import Foundation

extension NetworkHelper {
    func post<T: Encodable, U: Decodable>(
        urlString: String,
        body: T,
        completion: @escaping (Result<U, NetworkErrorType>) -> Void
    ) {
        guard let jsonData = try? JSONEncoder().encode(body),
              let request = createRequest(urlString: urlString, httpMethod: "POST", body: jsonData)
        else {
            completion(.failure(.invalidURL))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            self.handleResponse(data, response, error, completion: completion)
        }.resume()
    }
}
