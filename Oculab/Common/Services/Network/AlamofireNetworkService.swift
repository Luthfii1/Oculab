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
    
    func get<T: Decodable>(urlString: String, headers: [String: String]?) async throws -> APIResponse<T> {
        let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
        let request = AF.request(urlString, method: .get, headers: afHeaders)
        return try await handleRequest(request, endpoint: urlString)
    }

    func post<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B) async throws -> APIResponse<T> {
        let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
        let request = AF.request(urlString, method: .post, parameters: body, encoder: JSONParameterEncoder.default, headers: afHeaders)
        return try await handleRequest(request, endpoint: urlString)
    }

    func update<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B) async throws -> APIResponse<T> {
        let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
        let request = AF.request(urlString, method: .put, parameters: body, encoder: JSONParameterEncoder.default, headers: afHeaders)
        return try await handleRequest(request, endpoint: urlString)
    }

    func delete<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B?) async throws -> APIResponse<T> {
        let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
        let request = AF.request(urlString, method: .delete, parameters: body, encoder: JSONParameterEncoder.default, headers: afHeaders)
        return try await handleRequest(request, endpoint: urlString)
    }

    func multipart<T: Decodable>(urlString: String, headers: [String: String]?, parameters: [String: Data], boundary: String?) async throws -> APIResponse<T> {
        let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
        let request = AF.upload(multipartFormData: { multipartFormData in
            for (key, value) in parameters {
                multipartFormData.append(value, withName: key, fileName: "\(key).mov", mimeType: "video/quicktime")
            }
        }, to: urlString, headers: afHeaders)
        
        return try await handleRequest(request, endpoint: urlString)
    }

    private func handleRequest<T: Decodable>(_ request: DataRequest, endpoint: String) async throws -> APIResponse<T> {
        let dataResponse = await request.serializingData().response
        
        // Get the data regardless of success or failure
        guard let data = dataResponse.data else {
            throw NetworkError.networkError("No data received from server", endpoint: endpoint)
        }
        
        // Debug: Print API endpoint and response details
        if let statusCode = dataResponse.response?.statusCode {
            print("DEBUG: API Endpoint: \(endpoint)")
            print("DEBUG: HTTP Status Code: \(statusCode)")
        }
        
        if let rawString = String(data: data, encoding: .utf8) {
            print("DEBUG: Raw Response: \(rawString)")
        }
        
        // Always try to decode the response as our standard API format first
        if let errorResponse = try? Self.decoder.decode(APIResponse<ApiErrorData>.self, from: data) {
            print("DEBUG: Successfully decoded as APIResponse<ApiErrorData>")
            throw NetworkError.apiError(errorResponse, endpoint: endpoint)
        }
        
        // If it's not an error response, try to decode as success
        do {
            let decodedResponse = try Self.decoder.decode(APIResponse<T>.self, from: data)
            if decodedResponse.status == StatusResponseType.ERROR.rawValue {
                if let errorResponse = try? Self.decoder.decode(APIResponse<ApiErrorData>.self, from: data) {
                    throw NetworkError.apiError(errorResponse, endpoint: endpoint)
                }
            }
            return decodedResponse
        } catch {
            print("DEBUG: Failed to decode as success response: \(error)")
            // If we can't decode the response, fall back to the original error
            if let originalError = dataResponse.error {
                throw NetworkError.networkError(originalError.localizedDescription, endpoint: endpoint)
            }
            throw NetworkError.networkError("Decoding error: \(error.localizedDescription)", endpoint: endpoint)
        }
    }
}
