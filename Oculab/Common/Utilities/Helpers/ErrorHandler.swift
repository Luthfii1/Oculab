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
    func handleError(_ error: Error, context: ErrorHandler.ErrorContext) -> String
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
        case let NetworkError.apiError(apiResponse, endpoint):
            if let endpoint = endpoint {
                print("   🌐 API Endpoint: \(endpoint)")
            }
            print("   📡 API Error Type: \(apiResponse.data.errorType)")
            print("   📝 Description: \(apiResponse.data.description)")
            
        case let NetworkError.networkError(message, endpoint):
            if let endpoint = endpoint {
                print("   🌐 API Endpoint: \(endpoint)")
            }
            print("   🌐 Network Message: \(message)")
            if message.contains("retry attempts failed") {
                print("   🔄 All retry attempts exhausted")
            }

        case let NetworkError.unauthorized(endpoint):
            if let endpoint = endpoint {
                print("   🌐 API Endpoint: \(endpoint)")
            }
            print("   🔐 Unauthorized — access token rejected")
            
        case URLError.userAuthenticationRequired:
            print("   🔐 Authentication required")
            
        default:
            print("   ❓ Unknown error type")
        }
        #endif
    }
    
    func shouldShowRetryOption(for error: Error) -> Bool {
        switch error {
        case let NetworkError.networkError(message, _):
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

        case NetworkError.unauthorized:
            return false
            
        default:
            return true
        }
    }
    
    func getRetryDelay(for error: Error) -> TimeInterval? {
        switch error {
        case let NetworkError.networkError(message, _):
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
        case let NetworkError.apiError(apiResponse, _):
            return apiResponse.data.description.isEmpty ? 
                AppError.generic : apiResponse.data.description
            
        case let NetworkError.networkError(message, _):
            // Handle retry-specific messages
            if message.contains("retry attempts failed") {
                return "error.network_retry_failed".localized
            } else if message.contains("Operation already in progress") {
                return "error.operation_in_progress".localized
            } else if message.contains("Request timed out") {
                return AppError.Context.networkConnection
            } else if message.contains("Server error")
                        || message.contains("Decoding error")
                        || message.contains("isn't in the correct format")
                        || message.contains("Bad gateway") {
                return "error.server_temporarily_unavailable".localized
            } else if message.isEmpty {
                return AppError.networkConnection
            } else {
                return message
            }

        case NetworkError.unauthorized:
            return "error.authentication_required".localized
            
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
            return error.localizedDescription.isEmpty ? 
                AppError.unknownError : error.localizedDescription
        }
    }
    
    /// Handle errors with context-specific fallback messages
    /// - Parameters:
    ///   - error: The error to handle
    ///   - context: The context for localized fallback
    /// - Returns: User-friendly error message string
    func handleError(_ error: Error, context: ErrorContext) -> String {
        let errorMessage = mapErrorToUserMessage(error)
        logError(error, context: context.rawValue)
        
        // If we got a generic message, use context-specific fallback
        if errorMessage == AppError.generic || errorMessage == AppError.unknownError {
            return context.localizedFallbackMessage
        }
        
        return errorMessage
    }
}

// MARK: - Error Extensions
extension Error {
    var userFriendlyMessage: String {
        return ErrorHandler.shared.handleError(self)
    }
}

// MARK: - Error Context Enum
extension ErrorHandler {
    enum ErrorContext: String, CaseIterable {
        case login = "Login"
        case registration = "Registration"
        case profile = "Profile"
        case patientManagement = "Patient Management"
        case examination = "Examination"
        case networkConnection = "Network Connection"
        case generic = "Generic"
        
        var localizedFallbackMessage: String {
            switch self {
            case .login:
                return AppTextAuthLogin.loginFailedText
            case .registration:
                return AppTextUserMgmtView.failedRegistration
            case .profile:
                return AppError.Context.profile
            case .patientManagement:
                return AppError.Context.patientManagement
            case .examination:
                return AppError.Context.examination
            case .networkConnection:
                return AppError.Context.networkConnection
            case .generic:
                return AppError.generic
            }
        }
    }
}
