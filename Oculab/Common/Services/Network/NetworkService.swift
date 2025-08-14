//
//  NetworkService.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 12/08/25.
//

import Foundation
import Alamofire

/// Enhanced network service with retry logic, timeout handling, and better error recovery
class NetworkService: NetworkServiceProtocol {
    
    // MARK: - Dependencies
    
    private let retryManager: NetworkRetryManager
    private let baseService: AlamofireNetworkService
    private static let decoder = JSONDecoder()
    
    // MARK: - Configuration
    
    private struct NetworkConfig {
        static let requestTimeout: TimeInterval = 30.0
        static let maxRetryAttempts = 3
        
        // Different retry strategies for different operations
        static let criticalOperations = ["login", "logout", "getAccountById"]
        static let backgroundOperations = ["analytics", "logging"]
    }
    
    // MARK: - Initialization
    
    init(retryManager: NetworkRetryManager = NetworkRetryManager()) {
        self.retryManager = retryManager
        self.baseService = AlamofireNetworkService()
    }
    
    // MARK: - NetworkServiceProtocol Implementation with Retry Logic
    
    func get<T: Decodable>(
        urlString: String, 
        headers: [String: String]?
    ) async throws -> APIResponse<T> {
        
        let operationId = "GET_\(urlString.hashValue)"
        let maxAttempts = getRetryAttempts(for: urlString)
        
        return try await retryManager.executeWithRetry(
            id: operationId,
            maxAttempts: maxAttempts
        ) {
            try await self.performGetRequest(urlString: urlString, headers: headers)
        }
    }
    
    func post<T: Decodable, B: Encodable>(
        urlString: String, 
        headers: [String: String]?, 
        body: B
    ) async throws -> APIResponse<T> {
        
        let operationId = "POST_\(urlString.hashValue)"
        let maxAttempts = getRetryAttempts(for: urlString)
        
        return try await retryManager.executeWithRetry(
            id: operationId,
            maxAttempts: maxAttempts
        ) {
            try await self.performPostRequest(urlString: urlString, headers: headers, body: body)
        }
    }
    
    func update<T: Decodable, B: Encodable>(
        urlString: String, 
        headers: [String: String]?, 
        body: B
    ) async throws -> APIResponse<T> {
        
        let operationId = "PUT_\(urlString.hashValue)"
        let maxAttempts = getRetryAttempts(for: urlString)
        
        return try await retryManager.executeWithRetry(
            id: operationId,
            maxAttempts: maxAttempts
        ) {
            try await self.performUpdateRequest(urlString: urlString, headers: headers, body: body)
        }
    }
    
    func delete<T: Decodable, B: Encodable>(
        urlString: String, 
        headers: [String: String]?, 
        body: B?
    ) async throws -> APIResponse<T> {
        
        let operationId = "DELETE_\(urlString.hashValue)"
        let maxAttempts = getRetryAttempts(for: urlString)
        
        return try await retryManager.executeWithRetry(
            id: operationId,
            maxAttempts: maxAttempts
        ) {
            try await self.performDeleteRequest(urlString: urlString, headers: headers, body: body)
        }
    }
    
    func multipart<T: Decodable>(
        urlString: String, 
        headers: [String: String]?, 
        parameters: [String: Data], 
        boundary: String?
    ) async throws -> APIResponse<T> {
        
        let operationId = "MULTIPART_\(urlString.hashValue)"
        // Multipart uploads typically take longer, so fewer retries
        let maxAttempts = max(1, NetworkConfig.maxRetryAttempts - 1)
        
        return try await retryManager.executeWithRetry(
            id: operationId,
            maxAttempts: maxAttempts
        ) {
            try await self.performMultipartRequest(
                urlString: urlString, 
                headers: headers, 
                parameters: parameters, 
                boundary: boundary
            )
        }
    }
    
    // MARK: - Private Request Methods
    
    private func performGetRequest<T: Decodable>(
        urlString: String, 
        headers: [String: String]?
    ) async throws -> APIResponse<T> {
        
        let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
        let request = AF.request(urlString, method: .get, headers: afHeaders)
            .validate()
            .responseTimeout(NetworkConfig.requestTimeout)
        
        return try await handleRequest(request)
    }
    
    private func performPostRequest<T: Decodable, B: Encodable>(
        urlString: String, 
        headers: [String: String]?, 
        body: B
    ) async throws -> APIResponse<T> {
        
        let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
        let request = AF.request(
            urlString, 
            method: .post, 
            parameters: body, 
            encoder: JSONParameterEncoder.default, 
            headers: afHeaders
        )
        .validate()
        .responseTimeout(NetworkConfig.requestTimeout)
        
        return try await handleRequest(request)
    }
    
    private func performUpdateRequest<T: Decodable, B: Encodable>(
        urlString: String, 
        headers: [String: String]?, 
        body: B
    ) async throws -> APIResponse<T> {
        
        let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
        let request = AF.request(
            urlString, 
            method: .put, 
            parameters: body, 
            encoder: JSONParameterEncoder.default, 
            headers: afHeaders
        )
        .validate()
        .responseTimeout(NetworkConfig.requestTimeout)
        
        return try await handleRequest(request)
    }
    
    private func performDeleteRequest<T: Decodable, B: Encodable>(
        urlString: String, 
        headers: [String: String]?, 
        body: B?
    ) async throws -> APIResponse<T> {
        
        let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
        let request = AF.request(
            urlString, 
            method: .delete, 
            parameters: body, 
            encoder: JSONParameterEncoder.default, 
            headers: afHeaders
        )
        .validate()
        .responseTimeout(NetworkConfig.requestTimeout)
        
        return try await handleRequest(request)
    }
    
    private func performMultipartRequest<T: Decodable>(
        urlString: String, 
        headers: [String: String]?, 
        parameters: [String: Data], 
        boundary: String?
    ) async throws -> APIResponse<T> {
        
        let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
        let request = AF.upload(multipartFormData: { multipartFormData in
            for (key, value) in parameters {
                multipartFormData.append(value, withName: key, fileName: "\(key).mov", mimeType: "video/quicktime")
            }
        }, to: urlString, headers: afHeaders)
        .validate()
        .responseTimeout(NetworkConfig.requestTimeout * 2) // Longer timeout for uploads
        
        return try await handleRequest(request)
    }
    
    // MARK: - Enhanced Request Handling
    
    private func handleRequest<T: Decodable>(_ request: DataRequest) async throws -> APIResponse<T> {
        let dataResponse = await request.serializingData().response
        
        switch dataResponse.result {
        case .success(let data):
            return try await processSuccessfulResponse(data: data)
            
        case .failure(let afError):
            throw try await processFailedResponse(error: afError, data: dataResponse.data)
        }
    }
    
    private func processSuccessfulResponse<T: Decodable>(data: Data) async throws -> APIResponse<T> {
        do {
            let decodedResponse = try Self.decoder.decode(APIResponse<T>.self, from: data)
            
            // Check if the API returned an error status
            if decodedResponse.status == StatusResponseType.ERROR.rawValue {
                if let errorResponse = try? Self.decoder.decode(APIResponse<ApiErrorData>.self, from: data) {
                    throw NetworkError.apiError(errorResponse)
                }
            }
            
            return decodedResponse
            
        } catch let decodingError {
            // Try to decode as error response first
            if let errorResponse = try? Self.decoder.decode(APIResponse<ApiErrorData>.self, from: data) {
                throw NetworkError.apiError(errorResponse)
            }
            
            // If that fails, throw a decoding error
            throw NetworkError.networkError("Response decoding failed: \(decodingError.localizedDescription)")
        }
    }
    
    private func processFailedResponse(error: AFError, data: Data?) async throws -> NetworkError {
        // Check if we have response data that might contain error details
        if let data = data,
           let errorResponse = try? Self.decoder.decode(APIResponse<ApiErrorData>.self, from: data) {
            return NetworkError.apiError(errorResponse)
        }
        
        // Map AFError to appropriate NetworkError
        switch error {
        case .sessionTaskFailed(let sessionError):
            if let urlError = sessionError as? URLError {
                switch urlError.code {
                case .timedOut:
                    return NetworkError.networkError("Request timed out")
                case .notConnectedToInternet:
                    return NetworkError.networkError("No internet connection")
                case .cannotConnectToHost:
                    return NetworkError.networkError("Cannot connect to server")
                default:
                    return NetworkError.networkError("Network error: \(urlError.localizedDescription)")
                }
            }
            return NetworkError.networkError("Session task failed: \(sessionError.localizedDescription)")
            
            case .responseValidationFailed(let reason):
            switch reason {
            case .unacceptableStatusCode(let code):
                if code >= 500 {
                    return NetworkError.serverError("Server error (HTTP \(code))")
                } else if code == 401 {
                    return NetworkError.networkError("Authentication required")
                } else {
                    return NetworkError.networkError("HTTP error \(code)")
                }
            default:
                return NetworkError.networkError("Response validation failed")
            }        default:
            return NetworkError.networkError("Network request failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Retry Strategy
    
    private func getRetryAttempts(for urlString: String) -> Int {
        // Critical operations get more retries
        if NetworkConfig.criticalOperations.contains(where: { urlString.contains($0) }) {
            return NetworkConfig.maxRetryAttempts + 1
        }
        
        // Background operations get fewer retries
        if NetworkConfig.backgroundOperations.contains(where: { urlString.contains($0) }) {
            return max(1, NetworkConfig.maxRetryAttempts - 1)
        }
        
        // Default retry attempts
        return NetworkConfig.maxRetryAttempts
    }
}

// MARK: - Alamofire Extensions

private extension DataRequest {
    func responseTimeout(_ timeout: TimeInterval) -> DataRequest {
        return self.responseTimeout(timeout)
    }
}

// MARK: - Enhanced Network Errors

extension NetworkError {
    static func serverError(_ message: String) -> NetworkError {
        return .networkError("Server Error: \(message)")
    }
}
