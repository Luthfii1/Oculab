//
//  NetworkHelper.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 22/10/24.
//

import Foundation

@available(*, deprecated, message: "Use NetworkService protocol instead")
class NetworkHelper {
    static let shared = NetworkHelper()
    private init() {}

    // Function to create the basic request
    // Function to create the basic request
    @available(*, deprecated, message: "Use a class conforming to NetworkService instead")
    func createRequest(urlString: String, httpMethod: String, body: Data?) -> URLRequest? {
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }

    @available(*, deprecated, message: "Use a class conforming to NetworkService instead")
    func handleAsyncResponse<T: Decodable>(data: Data, response: URLResponse) throws -> APIResponse<T> {
        guard response is HTTPURLResponse else {
            throw NetworkError.networkError("Invalid response type")
        }

//        MARK: debug response

//        debugResponse(data: data)

        do {
            let decodedResponse = try JSONDecoder().decode(APIResponse<T>.self, from: data)
            if decodedResponse.status == StatusResponseType.ERROR.rawValue {
                // If the API returns an error response, decode it as an error
                if let errorResponse = try? JSONDecoder().decode(APIResponse<ApiErrorData>.self, from: data) {
                    throw NetworkError.apiError(errorResponse)
                }
            }
            return decodedResponse
        } catch {
            if let decodedError = try? JSONDecoder().decode(APIResponse<ApiErrorData>.self, from: data) {
                throw NetworkError.apiError(decodedError)
            }
            throw NetworkError.networkError("Decoding error: \(error.localizedDescription)")
        }
    }

    // Function to create a multipart request
    @available(*, deprecated, message: "Use a class conforming to NetworkService instead")
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
    @available(*, deprecated, message: "This function should not be part of the network layer")
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
    @available(*, deprecated, message: "Use a proper logging framework instead")
    func debugResponse(data: Data) {
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Response data: \(jsonString)") // For debugging
        } else {
            print("Failed to convert data to string.")
        }
    }
}
