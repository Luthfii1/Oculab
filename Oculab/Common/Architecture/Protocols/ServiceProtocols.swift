//
//  ServiceProtocols.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 12/08/25.
//

import Foundation

// MARK: - Authentication Service Protocol
protocol AuthenticationServiceProtocol {
    func login(email: String, password: String) async throws -> User
    func logout() async throws
    func validatePin(_ pin: String, for user: User) async throws -> Bool
    func createPin(_ pin: String, for user: User) async throws
    func authenticateWithBiometrics() async throws -> Bool
    func isUserLoggedIn() -> Bool
    func getCurrentUser() async throws -> User?
}

// MARK: - Data Storage Protocol
protocol DataStorageProtocol {
    func save<T: Codable>(_ object: T, forKey key: String) throws
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T?
    func delete(forKey key: String) throws
    func exists(forKey key: String) -> Bool
}

// MARK: - Validation Service Protocol
protocol ValidationServiceProtocol {
    func validateEmail(_ email: String) -> ValidationResult
    func validatePassword(_ password: String) -> ValidationResult
    func validatePin(_ pin: String) -> ValidationResult
    func validateName(_ name: String) -> ValidationResult
}

// MARK: - Biometric Authentication Protocol
protocol BiometricAuthenticationProtocol {
    func isBiometricAvailable() -> Bool
    func getBiometricType() -> BiometricType
    func authenticateWithBiometric() async throws -> Bool
    func canUseBiometric() -> Bool
}

// MARK: - Supporting Types
enum BiometricType {
    case faceID
    case touchID
    case none
}

// MARK: - Validation Result
struct ValidationResult {
    let isValid: Bool
    let errorMessage: String?
    
    static let valid = ValidationResult(isValid: true, errorMessage: nil)
    
    static func invalid(_ message: String) -> ValidationResult {
        ValidationResult(isValid: false, errorMessage: message)
    }
    
    static func invalid(localizedKey: String) -> ValidationResult {
        ValidationResult(isValid: false, errorMessage: localizedKey.localized)
    }
}

// MARK: - Validation Result Extensions
extension ValidationResult {
    var localizedErrorMessage: String? {
        return errorMessage?.localized
    }
    
    func throwIfInvalid() throws {
        if !isValid {
            throw ValidationError(message: errorMessage ?? AppValue.unknownError)
        }
    }
}

// MARK: - Validation Error
struct ValidationError: LocalizedError {
    let message: String
    
    var errorDescription: String? {
        return message
    }
    
    var localizedDescription: String {
        return message
    }
}
