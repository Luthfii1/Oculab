//
//  ErrorHandler.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 12/08/25.
//

import Foundation

// MARK: - Error Handler Protocol
protocol ErrorHandlerProtocol {
    func handleError(_ error: Error) -> String
    func logError(_ error: Error, context: String)
}

// MARK: - Error Handler Implementation
class ErrorHandler: ErrorHandlerProtocol {
    static let shared = ErrorHandler()
    
    private init() {}
    
    func handleError(_ error: Error) -> String {
        let errorMessage = mapErrorToUserMessage(error)
        logError(error, context: "User Error")
        return errorMessage
    }
    
    func logError(_ error: Error, context: String) {
        #if DEBUG
        print("🚨 ERROR [\(context)]: \(error.localizedDescription)")
        
        // Log additional details for specific error types
        switch error {
        case let NetworkError.apiError(apiResponse):
            print("   📡 API Error Type: \(apiResponse.data.errorType)")
            print("   📝 Description: \(apiResponse.data.description)")
            
        case let NetworkError.networkError(message):
            print("   🌐 Network Message: \(message)")
            
        case URLError.userAuthenticationRequired:
            print("   🔐 Authentication required")
            
        default:
            print("   ❓ Unknown error type")
        }
        #endif
    }
    
    private func mapErrorToUserMessage(_ error: Error) -> String {
        switch error {
        case let NetworkError.apiError(apiResponse):
            return apiResponse.data.description
            
        case let NetworkError.networkError(message):
            return "error.network_error".localized(with: [message])
            
        case URLError.userAuthenticationRequired:
            return "error.authentication_required".localized
            
        case URLError.notConnectedToInternet:
            return "error.no_internet_connection".localized
            
        case URLError.timedOut:
            return "error.request_timeout".localized
            
        default:
            return "error.unexpected_error".localized
        }
    }
}

// MARK: - Error Extensions
extension Error {
    var userFriendlyMessage: String {
        return ErrorHandler.shared.handleError(self)
    }
}
