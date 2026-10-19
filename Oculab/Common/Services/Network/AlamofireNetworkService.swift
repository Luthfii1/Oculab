//
//  AlamofireNetworkService.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 7/5/25.
//

import Foundation
import Alamofire

class AlamofireNetworkService: NetworkServiceProtocol {
    private let session: Session

    init(session: Session = .default) {
        self.session = session
    }

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
            let request = self.session.request(urlString, method: .get, headers: afHeaders)
            return try await self.handleRequest(request, endpoint: urlString)
        }
    }

    func post<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B) async throws -> APIResponse<T> {
        try await executeWithAuthRetry(endpoint: urlString, headers: headers) { headers in
            let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
            let request = self.session.request(
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
            let request = self.session.request(
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
            let request = self.session.request(
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

    func multipartFile<T: Decodable>(
        urlString: String,
        headers: [String: String]?,
        fileURL: URL,
        fieldName: String,
        fileName: String?,
        mimeType: String?
    ) async throws -> APIResponse<T> {
        let resolvedFileName = fileName ?? fileURL.lastPathComponent
        let resolvedMime = mimeType ?? Self.mimeType(for: fileURL)

        return try await executeWithAuthRetry(endpoint: urlString, headers: headers) { headers in
            let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
            let request = Self.uploadSession.upload(
                multipartFormData: { multipartFormData in
                    multipartFormData.append(
                        fileURL,
                        withName: fieldName,
                        fileName: resolvedFileName,
                        mimeType: resolvedMime
                    )
                },
                to: urlString,
                headers: afHeaders
            )
            return try await self.handleRequest(request, endpoint: urlString)
        }
    }

    private static func mimeType(for fileURL: URL) -> String {
        switch fileURL.pathExtension.lowercased() {
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        case "avi":
            return "video/x-msvideo"
        case "webm":
            return "video/webm"
        default:
            return "video/quicktime"
        }
    }

    private func executeWithAuthRetry<T>(
        endpoint: String,
        headers: [String: String]?,
        perform: ([String: String]?) async throws -> APIResponse<T>
    ) async throws -> APIResponse<T> {
        let (initialHeaders, generation) = try await MainActor.run {
            (try resolveHeaders(for: endpoint, headers: headers), AuthSessionManager.authenticationSessionGeneration)
        }
        try Task.checkCancellation()

        do {
            return try await perform(initialHeaders)
        } catch NetworkError.unauthorized {
            try Task.checkCancellation()
            guard await MainActor.run(body: { generation == AuthSessionManager.authenticationSessionGeneration }) else {
                throw CancellationError()
            }
            // A rejected login or refresh request must not invalidate the session here.
            // The caller of the refresh handles its authentication failure once.
            guard AuthSessionManager.requiresAuthentication(for: endpoint) else {
                throw NetworkError.unauthorized(endpoint: endpoint)
            }
            guard AuthSessionManager.shouldAttemptTokenRefresh(for: endpoint) else {
                try await MainActor.run { try AuthSessionManager.invalidateSession(ifGeneration: generation) }
                throw NetworkError.unauthorized(endpoint: endpoint)
            }

            do {
                try await AuthTokenRefresher.shared.refreshAccessToken(using: self, expectedGeneration: generation)
            } catch NetworkError.unauthorized {
                try await MainActor.run { try AuthSessionManager.invalidateSession(ifGeneration: generation) }
                throw NetworkError.unauthorized(endpoint: endpoint)
            }

            try Task.checkCancellation()
            let refreshedHeaders = try await MainActor.run {
                guard generation == AuthSessionManager.authenticationSessionGeneration else { throw CancellationError() }
                return try AuthSessionManager.headersByReplacingAuthorization(headers)
            }
            do {
                return try await perform(refreshedHeaders)
            } catch NetworkError.unauthorized {
                try await MainActor.run { try AuthSessionManager.invalidateSession(ifGeneration: generation) }
                throw NetworkError.unauthorized(endpoint: endpoint)
            }
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
        try Task.checkCancellation()

        let statusCode = dataResponse.response?.statusCode
        // DataResponseSerializer rejects empty bodies outside 204/205. A complete
        // HTTP rejection still carries policy even when there is no JSON body.
        // Genuine connection/task failures remain ambiguous transport failures.
        if let error = dataResponse.error {
            if error.isExplicitlyCancelledError { throw CancellationError() }
            if !error.isResponseSerializationError {
                if let underlying = error.underlyingError { throw underlying }
                throw NetworkError.networkError(error.localizedDescription, endpoint: endpoint)
            }
        }
        if UploadRequestContext.preservesHTTPMetadata, let statusCode, !(200...299).contains(statusCode) {
            if statusCode == 401 { throw NetworkError.unauthorized(endpoint: endpoint) }
            let envelope = try? JSONDecoder().decode(APIResponse<ApiErrorData>.self, from: dataResponse.data ?? Data())
            let underlying: NetworkError = envelope.map { .apiError($0, endpoint: endpoint) }
                ?? .networkError("Request failed (\(statusCode))", endpoint: endpoint)
            throw UploadHTTPFailure(
                statusCode: statusCode,
                retryAfter: UploadHTTPFailure.retryDate(dataResponse.response?.value(forHTTPHeaderField: "Retry-After")),
                underlying: underlying
            )
        }

        if let error = dataResponse.error {
            if UploadRequestContext.preservesHTTPMetadata { throw UploadProtocolFailure() }
            if let underlying = error.underlyingError { throw underlying }
            throw NetworkError.networkError(error.localizedDescription, endpoint: endpoint)
        }

        guard let data = dataResponse.data else {
            throw NetworkError.networkError("No data received from server", endpoint: endpoint)
        }

        #if DEBUG
        if let statusCode {
            print("DEBUG: API Endpoint: \(endpoint)")
            print("DEBUG: HTTP Status Code: \(statusCode)")
        }
        #endif

        if UploadRequestContext.preservesHTTPMetadata,
           let statusCode, (200...299).contains(statusCode), isNonJSONResponse(data) {
            throw UploadProtocolFailure()
        }
        try validateHTTPResponse(data: data, statusCode: statusCode, endpoint: endpoint)

        let decoder = JSONDecoder()
        if let errorResponse = try? decoder.decode(APIResponse<ApiErrorData>.self, from: data),
           errorResponse.status == StatusResponseType.ERROR.rawValue {
            #if DEBUG
            print("DEBUG: Successfully decoded as APIResponse<ApiErrorData>")
            #endif
            throw NetworkError.apiError(errorResponse, endpoint: endpoint)
        }

        guard let statusCode, (200...299).contains(statusCode) else {
            throw NetworkError.networkError("Request failed (\(statusCode ?? 0))", endpoint: endpoint)
        }

        do {
            var decodedResponse = try decoder.decode(APIResponse<T>.self, from: data)
            if UploadRequestContext.preservesHTTPMetadata {
                decodedResponse.retryAfter = UploadHTTPFailure.retryDate(dataResponse.response?.value(forHTTPHeaderField: "Retry-After"))
                decodedResponse.httpStatusCode = statusCode
            }
            if decodedResponse.status == StatusResponseType.ERROR.rawValue {
                throw NetworkError.networkError(decodedResponse.message, endpoint: endpoint)
            }
            return decodedResponse
        } catch let decodingError as NetworkError {
            throw decodingError
        } catch {
            if UploadRequestContext.preservesHTTPMetadata { throw UploadProtocolFailure() }
            #if DEBUG
            print("DEBUG: Failed to decode as success response: \(error)")
            #endif
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
