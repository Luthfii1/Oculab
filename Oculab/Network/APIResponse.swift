//
//  APIResponse.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 22/10/24.
//

import Foundation

struct APIResponse<T: Decodable>: Decodable, Error {
    let status: String
    let code: Int
    let message: String
    let data: T

    enum CodingKeys: String, CodingKey {
        case status
        case code
        case message
        case data
    }

    init(status: String, code: Int, message: String, data: T) {
        self.status = status
        self.code = code
        self.message = message
        self.data = data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.status = try container.decode(String.self, forKey: .status)
        self.code = try container.decode(Int.self, forKey: .code)
        self.message = try container.decode(String.self, forKey: .message)
        self.data = try container.decode(T.self, forKey: .data)
    }
}

enum StatusResponseType: String, Codable {
    case SUCCESS = "success"
    case ERROR = "error"
}

struct ApiErrorData: Decodable, Error {
    let errorType: String
    let description: String
}
