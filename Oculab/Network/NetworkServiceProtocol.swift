//
//  NetworkServiceProtocol.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 7/5/25.
//

import Foundation

protocol NetworkServiceProtocol {
    func get<T: Decodable>(urlString: String, headers: [String: String]?) async throws -> APIResponse<T>
    func post<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B) async throws -> APIResponse<T>
    func update<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B) async throws -> APIResponse<T>
    func delete<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B?) async throws -> APIResponse<T>
    func multipart<T: Decodable>(urlString: String, headers: [String: String]?, parameters: [String: Data], boundary: String?) async throws -> APIResponse<T>
}
