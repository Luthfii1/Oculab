//
//  MockNetworkService.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 7/5/25.
//

import Foundation

class MockNetworkService: NetworkServiceProtocol {
    var getShouldSucceed = true
    var postShouldSucceed = true
    var updateShouldSucceed = true
    var deleteShouldSucceed = true
    var multipartShouldSucceed = true

    func get<T: Decodable>(urlString: String, headers: [String: String]?) async throws -> APIResponse<T> {
        if getShouldSucceed {
            let data = "{\"status\":\"success\",\"code\":200,\"message\":\"Success\",\"data\":{}}".data(using: .utf8)!
            let decodedResponse = try JSONDecoder().decode(APIResponse<T>.self, from: data)
            return decodedResponse
        } else {
            throw NetworkError.networkError("Mock GET failed")
        }
    }

    func post<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B) async throws -> APIResponse<T> {
        if postShouldSucceed {
            let data = "{\"status\":\"success\",\"code\":200,\"message\":\"Success\",\"data\":{}}".data(using: .utf8)!
            let decodedResponse = try JSONDecoder().decode(APIResponse<T>.self, from: data)
            return decodedResponse
        } else {
            throw NetworkError.networkError("Mock POST failed")
        }
    }

    func update<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B) async throws -> APIResponse<T> {
        if updateShouldSucceed {
            let data = "{\"status\":\"success\",\"code\":200,\"message\":\"Success\",\"data\":{}}".data(using: .utf8)!
            let decodedResponse = try JSONDecoder().decode(APIResponse<T>.self, from: data)
            return decodedResponse
        } else {
            throw NetworkError.networkError("Mock UPDATE failed")
        }
    }

    func delete<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B?) async throws -> APIResponse<T> {
        if deleteShouldSucceed {
            let data = "{\"status\":\"success\",\"code\":200,\"message\":\"Success\",\"data\":{}}".data(using: .utf8)!
            let decodedResponse = try JSONDecoder().decode(APIResponse<T>.self, from: data)
            return decodedResponse
        } else {
            throw NetworkError.networkError("Mock DELETE failed")
        }
    }

    func multipart<T: Decodable>(urlString: String, headers: [String: String]?, parameters: [String: Data], boundary: String?) async throws -> APIResponse<T> {
        if multipartShouldSucceed {
            let data = "{\"status\":\"success\",\"code\":200,\"message\":\"Success\",\"data\":{}}".data(using: .utf8)!
            let decodedResponse = try JSONDecoder().decode(APIResponse<T>.self, from: data)
            return decodedResponse
        } else {
            throw NetworkError.networkError("Mock MULTIPART failed")
        }
    }
}
