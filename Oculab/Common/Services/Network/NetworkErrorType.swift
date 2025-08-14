//
//  NetworkErrorType.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 22/10/24.
//

import Foundation

enum NetworkErrorType: Error, LocalizedError, Decodable {
    case validationError(String)
    case resourceNotFound(String)
    case serverError(String)
    case authenticationError(String)
    case permissionError(String)
    case internalValidationError(String)
    case conflictError(String)
    case invalidUrl
    case decodedError
    case requestFailed(String)
    case noData
    case unexpectedResponse

    var errorDescription: String {
        switch self {
        case let .validationError(message),
             let .resourceNotFound(message),
             let .serverError(message),
             let .authenticationError(message),
             let .permissionError(message),
             let .internalValidationError(message),
             let .conflictError(message),
             let .requestFailed(message):
            return message
        case .invalidUrl:
            return "Invalid URL"
        case .decodedError:
            return "Decoding error"
        case .noData:
            return "No Data Provided"
        case .unexpectedResponse:
            return "Unexpected response from server"
        }
    }

    // Custom initializer for decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let errorType = try container.decode(String.self)
        self = NetworkErrorType(errorType: errorType, description: "Error description is unavailable")
    }

    // Custom initializer to map the error type from a string value
    init(errorType: String, description: String) {
        switch errorType {
        case "VALIDATION_ERROR":
            self = .validationError(description)
        case "RESOURCE_NOT_FOUND":
            self = .resourceNotFound(description)
        case "SERVER_ERROR":
            self = .serverError(description)
        case "AUTHENTICATION_ERROR":
            self = .authenticationError(description)
        case "PERMISSION_ERROR":
            self = .permissionError(description)
        case "INTERNAL_VALIDATION_ERROR":
            self = .internalValidationError(description)
        case "CONFLICT_ERROR":
            self = .conflictError(description)
        default:
            self = .serverError(description)
        }
    }
}

enum NetworkError: Error {
    case apiError(APIResponse<ApiErrorData>)
    case networkError(String)
}
