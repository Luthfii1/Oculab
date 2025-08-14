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
    func shouldShowRetryOption(for error: Error) -> Bool
    func getRetryDelay(for error: Error) -> TimeInterval?
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
            if message.contains("retry attempts failed") {
                print("   🔄 All retry attempts exhausted")
            }
            
        case URLError.userAuthenticationRequired:
            print("   🔐 Authentication required")
            
        default:
            print("   ❓ Unknown error type")
        }
        #endif
    }
    
    func shouldShowRetryOption(for error: Error) -> Bool {
        switch error {
        case let NetworkError.networkError(message):
            // Show retry for network issues but not for retry exhaustion
            return !message.contains("retry attempts failed") && 
                   !message.contains("Operation already in progress") &&
                   !message.contains("Authentication required")
            
        case URLError.timedOut, URLError.cannotConnectToHost, URLError.networkConnectionLost:
            return true
            
        case URLError.userAuthenticationRequired, URLError.userCancelledAuthentication:
            return false
            
        case NetworkError.apiError:
            return false
            
        default:
            return true
        }
    }
    
    func getRetryDelay(for error: Error) -> TimeInterval? {
        switch error {
        case let NetworkError.networkError(message):
            if message.contains("Server error") {
                return 5.0 // Server errors need more time
            }
            return 2.0
            
        case URLError.timedOut:
            return 3.0
            
        case URLError.cannotConnectToHost:
            return 1.0
            
        default:
            return 2.0
        }
    }
    
    private func mapErrorToUserMessage(_ error: Error) -> String {
        switch error {
        case let NetworkError.apiError(apiResponse):
            return apiResponse.data.description
            
        case let NetworkError.networkError(message):
            // Handle retry-specific messages
            if message.contains("retry attempts failed") {
                return "error.network_retry_failed".localized
            } else if message.contains("Operation already in progress") {
                return "error.operation_in_progress".localized
            } else if message.contains("Request timed out") {
                return "error.request_timeout".localized
            } else if message.contains("Server error") {
                return "error.server_temporarily_unavailable".localized
            } else {
                return "error.network_error".localized(with: [message])
            }
            
        case URLError.userAuthenticationRequired:
            return "error.authentication_required".localized
            
        case URLError.notConnectedToInternet:
            return "error.no_internet_connection".localized
            
        case URLError.timedOut:
            return "error.request_timeout".localized
            
        case URLError.cannotConnectToHost:
            return "error.cannot_connect_to_server".localized
            
        case URLError.networkConnectionLost:
            return "error.connection_lost".localized
            
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
