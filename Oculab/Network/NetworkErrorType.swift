//
//  NetworkErrorType.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 22/10/24.
//

import Foundation

enum NetworkErrorType: Error {
    case invalidURL // The URL provided is not valid
    case noData // No data received from the server
    case decodingError(Error) // Error during JSON decoding
    case requestFailed(Error) // The request failed (e.g., network issues)
    case encodingError(Error) // Error during JSON encoding
    case serverError(Int) // Server returned an error response (e.g., 404, 500)
    case unexpectedResponse // The response is in an unexpected format
    case unauthorized // The request was unauthorized (e.g., 401)
    case forbidden // Access to the resource is forbidden (e.g., 403)
}
