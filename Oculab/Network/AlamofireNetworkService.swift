//
//  AlamofireNetworkService.swift
//  Oculab
//
//  Created by Cline on 7/5/25.
//

import Foundation
import Alamofire

class AlamofireNetworkService: NetworkService {
    func get<T: Decodable>(urlString: String, headers: [String: String]?) async throws -> APIResponse<T> {
        let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
        let request = AF.request(urlString, method: .get, headers: afHeaders)
        return try await handleRequest(request)
    }

    func post<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B) async throws -> APIResponse<T> {
        let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
        let request = AF.request(urlString, method: .post, parameters: body, encoder: JSONParameterEncoder.default, headers: afHeaders)
        return try await handleRequest(request)
    }

    func update<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B) async throws -> APIResponse<T> {
        let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
        let request = AF.request(urlString, method: .put, parameters: body, encoder: JSONParameterEncoder.default, headers: afHeaders)
        return try await handleRequest(request)
    }

    func delete<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B?) async throws -> APIResponse<T> {
        let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
        let request = AF.request(urlString, method: .delete, parameters: body, encoder: JSONParameterEncoder.default, headers: afHeaders)
        return try await handleRequest(request)
    }

    func multipart<T: Decodable>(urlString: String, headers: [String: String]?, parameters: [String: Data], boundary: String?) async throws -> APIResponse<T> {
        let afHeaders = headers != nil ? HTTPHeaders(headers!) : nil
        let request = AF.upload(multipartFormData: { multipartFormData in
            for (key, value) in parameters {
                multipartFormData.append(value, withName: key, fileName: "\(key).mov", mimeType: "video/quicktime")
            }
        }, to: urlString, headers: afHeaders)
        
        return try await handleRequest(request)
    }

    private func handleRequest<T: Decodable>(_ request: DataRequest) async throws -> APIResponse<T> {
        let dataResponse = await request.validate().serializingData().response
        switch dataResponse.result {
        case .success(let data):
            do {
                let decodedResponse = try JSONDecoder().decode(APIResponse<T>.self, from: data)
                if decodedResponse.status == StatusResponseType.ERROR.rawValue {
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
        case .failure(let error):
            throw NetworkError.networkError(error.localizedDescription)
        }
    }
}
