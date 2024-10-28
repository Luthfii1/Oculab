//
//  NetworkHelper.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 22/10/24.
//

import Foundation

class NetworkHelper {
    static let shared = NetworkHelper()

    private init() {}

    func createRequest(urlString: String, httpMethod: String, body: Data?) -> URLRequest? {
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        return request
    }

    func handleResponse<T: Decodable>(
        _ data: Data?,
        _ response: URLResponse?,
        _ error: Error?,
        completion: @escaping (Result<T, NetworkErrorType>) -> Void
    ) {
        if let error = error {
            completion(.failure(.requestFailed(error)))
            return
        }

        guard let data = data else {
            completion(.failure(.noData))
            return
        }

        if let httpResponse = response as? HTTPURLResponse {
            if (400...499).contains(httpResponse.statusCode) {
                switch httpResponse.statusCode {
                case 401:
                    completion(.failure(.unauthorized))
                case 403:
                    completion(.failure(.forbidden))
                default:
                    completion(.failure(.serverError(httpResponse.statusCode)))
                }
                return
            }
        }

        do {
            let decodedData = try JSONDecoder().decode(T.self, from: data)
            completion(.success(decodedData))
        } catch {
            completion(.failure(.decodingError(error)))
        }
    }
}
