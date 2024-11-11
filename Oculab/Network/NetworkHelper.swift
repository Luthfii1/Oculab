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

    // Function to create the basic request
    func createRequest(urlString: String, httpMethod: String, body: Data?) -> URLRequest? {
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }

    // Function to handle the response
    func handleResponse<T: Decodable>(
        _ data: Data?,
        _ response: URLResponse?,
        _ error: Error?,
        completion: @escaping (Result<APIResponse<T>, APIResponse<ApiErrorData>>) -> Void
    ) {
        // Handle request error
        if let error = error {
            let errorResponse = createErrorSystem(
                errorType: "HANDLE_REQUEST_ERROR",
                errorMessage: "Error when handle request: \(error.localizedDescription)"
            )
            completion(.failure(errorResponse))
            return
        }

        // Ensure data exists
        guard let data = data else {
            let errorResponse = createErrorSystem(
                errorType: "DATA_NOT_FOUND",
                errorMessage: "Error when handle response: Data not found"
            )
            completion(.failure(errorResponse))
            return
        }

        // Print the data as a JSON string for debugging
        debugResponse(data: data)

        // Decode the response to determine success or error
        do {
            print("here")
            print(T.Type.self)
            let response = try JSONDecoder().decode(APIResponse<T>.self, from: data)
            print("success decoding")
            completion(.success(response))
        } catch {
            if let errorResponse = try? JSONDecoder().decode(APIResponse<ApiErrorData>.self, from: data) {
                completion(.failure(errorResponse))
            } else {
                completion(.failure(createErrorSystem(
                    errorType: "DECODING_ERROR",
                    errorMessage: "Error when decoding response: \(error.localizedDescription)"
                )))
            }
        }
    }

    // Function to create a multipart request
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

    // Function to create errorSystem from FE
    func createErrorSystem(errorType: String, errorMessage: String) -> APIResponse<ApiErrorData> {
        let apiErrorData = ApiErrorData(errorType: errorType, description: errorMessage)

        let apiResponse = APIResponse<ApiErrorData>(
            status: "error",
            code: -1,
            message: errorMessage,
            data: apiErrorData
        )
        return apiResponse
    }

    // Function to debug response
    func debugResponse(data: Data) {
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Response data: \(jsonString)") // For debugging
        } else {
            print("Failed to convert data to string.")
        }
    }
}
