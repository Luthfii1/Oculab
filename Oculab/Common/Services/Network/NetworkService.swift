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
    
    // MARK: - Configuration
    
    private struct NetworkConfig {
        static let requestTimeout: TimeInterval = 30.0
        static let maxRetryAttempts = 3
        
        // Different retry strategies for different operations
        static let criticalOperations = ["login", "logout", "get-user-data-by-id"]
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

    /// Video uploads bypass the short retry timeout — stream from disk via Alamofire.
    func multipartFile<T: Decodable>(
        urlString: String,
        headers: [String: String]?,
        fileURL: URL,
        fieldName: String,
        fileName: String?,
        mimeType: String?
    ) async throws -> APIResponse<T> {
        try await baseService.multipartFile(
            urlString: urlString,
            headers: headers,
            fileURL: fileURL,
            fieldName: fieldName,
            fileName: fileName,
            mimeType: mimeType
        )
    }
    
    // MARK: - Private Request Methods
    
    private func performGetRequest<T: Decodable>(
        urlString: String,
        headers: [String: String]?
    ) async throws -> APIResponse<T> {
        try await baseService.get(urlString: urlString, headers: headers)
    }

    private func performPostRequest<T: Decodable, B: Encodable>(
        urlString: String,
        headers: [String: String]?,
        body: B
    ) async throws -> APIResponse<T> {
        try await baseService.post(urlString: urlString, headers: headers, body: body)
    }

    private func performUpdateRequest<T: Decodable, B: Encodable>(
        urlString: String,
        headers: [String: String]?,
        body: B
    ) async throws -> APIResponse<T> {
        try await baseService.update(urlString: urlString, headers: headers, body: body)
    }

    private func performDeleteRequest<T: Decodable, B: Encodable>(
        urlString: String,
        headers: [String: String]?,
        body: B?
    ) async throws -> APIResponse<T> {
        try await baseService.delete(urlString: urlString, headers: headers, body: body)
    }

    private func performMultipartRequest<T: Decodable>(
        urlString: String,
        headers: [String: String]?,
        parameters: [String: Data],
        boundary: String?
    ) async throws -> APIResponse<T> {
        try await baseService.multipart(
            urlString: urlString,
            headers: headers,
            parameters: parameters,
            boundary: boundary
        )
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

// MARK: - Enhanced Network Errors

extension NetworkError {
    static func serverError(_ message: String) -> NetworkError {
        return .networkError("Server Error: \(message)")
    }
}
