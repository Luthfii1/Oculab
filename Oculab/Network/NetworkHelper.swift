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
            print("Decode error: \(error.localizedDescription)") // Print the error message
            completion(.failure(.decodingError(error)))
        }
    }

    func createMultipartRequest(
        urlString: String,
        httpMethod: String,
        parameters: [String: Data],
        boundary: String
    ) -> URLRequest? {
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Construct the multipart body
        var body = Data()
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body
                .append(
                    "Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(key).mov\"\r\n"
                        .data(using: .utf8)!
                )
            body.append("Content-Type: video/quicktime\r\n\r\n".data(using: .utf8)!)
            body.append(value)
            body.append("\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body
        request.setValue(String(body.count), forHTTPHeaderField: "Content-Length")

        return request
    }
}
