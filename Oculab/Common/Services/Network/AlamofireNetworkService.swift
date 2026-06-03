//
//  AlamofireNetworkService.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 7/5/25.
//

import Foundation
import Alamofire

class AlamofireNetworkService: NetworkServiceProtocol {
    private static let decoder = JSONDecoder()

    /// Video uploads chain through the API into ML processing; default ~60s timeouts are too short.
    private static let uploadSession: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 300
        configuration.timeoutIntervalForResource = 600
        return Session(configuration: configuration)
    }()

    func get<T: Decodable>(urlString: String, headers: [String: String]?) async throws -> APIResponse<T> {
        try await executeWithAuthRetry(endpoint: urlString, headers: headers) { headers in
            let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
            let request = AF.request(urlString, method: .get, headers: afHeaders)
            return try await self.handleRequest(request, endpoint: urlString)
        }
    }

    func post<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B) async throws -> APIResponse<T> {
        try await executeWithAuthRetry(endpoint: urlString, headers: headers) { headers in
            let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
            let request = AF.request(
                urlString,
                method: .post,
                parameters: body,
                encoder: JSONParameterEncoder.default,
                headers: afHeaders
            )
            return try await self.handleRequest(request, endpoint: urlString)
        }
    }

    func update<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B) async throws -> APIResponse<T> {
        try await executeWithAuthRetry(endpoint: urlString, headers: headers) { headers in
            let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
            let request = AF.request(
                urlString,
                method: .put,
                parameters: body,
                encoder: JSONParameterEncoder.default,
                headers: afHeaders
            )
            return try await self.handleRequest(request, endpoint: urlString)
        }
    }

    func delete<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B?) async throws -> APIResponse<T> {
        try await executeWithAuthRetry(endpoint: urlString, headers: headers) { headers in
            let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
            let request = AF.request(
                urlString,
                method: .delete,
                parameters: body,
                encoder: JSONParameterEncoder.default,
                headers: afHeaders
            )
            return try await self.handleRequest(request, endpoint: urlString)
        }
    }

    func multipart<T: Decodable>(
        urlString: String,
        headers: [String: String]?,
        parameters: [String: Data],
        boundary: String?
    ) async throws -> APIResponse<T> {
        try await executeWithAuthRetry(endpoint: urlString, headers: headers) { headers in
            let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
            let request = Self.uploadSession.upload(multipartFormData: { multipartFormData in
                for (key, value) in parameters {
                    multipartFormData.append(value, withName: key, fileName: "\(key).mov", mimeType: "video/quicktime")
                }
            }, to: urlString, headers: afHeaders)

            return try await self.handleRequest(request, endpoint: urlString)
        }
    }

    private func executeWithAuthRetry<T>(
        endpoint: String,
        headers: [String: String]?,
        perform: ([String: String]?) async throws -> APIResponse<T>
    ) async throws -> APIResponse<T> {
        let initialHeaders = try resolveHeaders(for: endpoint, headers: headers)

        do {
            return try await perform(initialHeaders)
        } catch NetworkError.unauthorized {
            guard AuthSessionManager.shouldAttemptTokenRefresh(for: endpoint) else {
                throw NetworkError.unauthorized(endpoint: endpoint)
            }

            try await AuthTokenRefresher.shared.refreshAccessToken(using: self)
            let refreshedHeaders = try AuthSessionManager.headersByReplacingAuthorization(headers)
            return try await perform(refreshedHeaders)
        }
    }

    /// Attach bearer token on the first request for protected endpoints (not only after a 401).
    private func resolveHeaders(for endpoint: String, headers: [String: String]?) throws -> [String: String]? {
        guard AuthSessionManager.shouldAttachAuthorization(to: endpoint) else {
            return headers
        }
        return try AuthSessionManager.headersByReplacingAuthorization(headers)
    }

    private func handleRequest<T: Decodable>(_ request: DataRequest, endpoint: String) async throws -> APIResponse<T> {
        let dataResponse = await request.serializingData().response

        guard let data = dataResponse.data else {
            if let error = dataResponse.error, isRequestTimedOut(error) {
                throw URLError(.timedOut)
            }
            throw NetworkError.networkError("No data received from server", endpoint: endpoint)
        }

        let statusCode = dataResponse.response?.statusCode

        #if DEBUG
        if let statusCode {
            print("DEBUG: API Endpoint: \(endpoint)")
            print("DEBUG: HTTP Status Code: \(statusCode)")
        }

        if let rawString = String(data: data, encoding: .utf8) {
            print("DEBUG: Raw Response: \(rawString)")
        }
        #endif

        try validateHTTPResponse(data: data, statusCode: statusCode, endpoint: endpoint)

        if let errorResponse = try? Self.decoder.decode(APIResponse<ApiErrorData>.self, from: data) {
            #if DEBUG
            print("DEBUG: Successfully decoded as APIResponse<ApiErrorData>")
            #endif
            throw NetworkError.apiError(errorResponse, endpoint: endpoint)
        }

        do {
            let decodedResponse = try Self.decoder.decode(APIResponse<T>.self, from: data)
            if decodedResponse.status == StatusResponseType.ERROR.rawValue {
                if let errorResponse = try? Self.decoder.decode(APIResponse<ApiErrorData>.self, from: data) {
                    throw NetworkError.apiError(errorResponse, endpoint: endpoint)
                }
            }
            return decodedResponse
        } catch let decodingError as NetworkError {
            throw decodingError
        } catch {
            #if DEBUG
            print("DEBUG: Failed to decode as success response: \(error)")
            #endif
            if let originalError = dataResponse.error {
                throw NetworkError.networkError(originalError.localizedDescription, endpoint: endpoint)
            }
            throw NetworkError.networkError("Server error", endpoint: endpoint)
        }
    }

    private func validateHTTPResponse(data: Data, statusCode: Int?, endpoint: String) throws {
        if statusCode == 401 {
            throw NetworkError.unauthorized(endpoint: endpoint)
        }

        if let statusCode, (500...599).contains(statusCode) {
            throw NetworkError.networkError("Server error (\(statusCode))", endpoint: endpoint)
        }

        if isNonJSONResponse(data) {
            throw NetworkError.networkError("Server error", endpoint: endpoint)
        }
    }

    private func isRequestTimedOut(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorTimedOut {
            return true
        }
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError,
           underlying.domain == NSURLErrorDomain,
           underlying.code == NSURLErrorTimedOut {
            return true
        }
        return false
    }

    private func isNonJSONResponse(_ data: Data) -> Bool {
        guard let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return false
        }

        guard let first = text.first else { return false }
        return first != "{" && first != "["
    }
}
