//
//  ValidationHelpers.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 12/08/25.
//

import Foundation

// MARK: - Validation Helpers
struct ValidationHelpers {
    
    // MARK: - Email Validation
    static func isValidEmail(_ email: String) -> Bool {
        guard !email.isEmpty else { return false }
        let emailRegex = ValidationConstants.emailRegexPattern
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    // MARK: - PIN Validation
    static func isValidPIN(_ pin: String) -> Bool {
        return pin.count == AppConstants.pinLength && pin.allSatisfy(\.isNumber)
    }
    
    static func isPINFormatValid(_ pin: String) -> Bool {
        return pin.count <= AppConstants.pinLength && pin.allSatisfy(\.isNumber)
    }
    
    // MARK: - Password Validation
    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= ValidationConstants.minPasswordLength &&
               password.count <= ValidationConstants.maxPasswordLength
    }
    
    // MARK: - Name Validation
    static func isValidName(_ name: String) -> Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Form Validation
    static func isLoginFormValid(email: String, password: String) -> Bool {
        return isValidEmail(email) && isValidPassword(password)
    }
    
    static func isUserFormValid(name: String, email: String, role: String) -> Bool {
        return isValidName(name) && isValidEmail(email) && !role.isEmpty
    }
}

// MARK: - Validation Error Messages
extension ValidationHelpers {
    enum ErrorMessage {
        static let invalidEmail = "validation.invalid_email".localized
        static let invalidPassword = "validation.invalid_password".localized(with: ["\(ValidationConstants.minPasswordLength)"])
        static let invalidPIN = "validation.invalid_pin".localized(with: ["\(AppConstants.pinLength)"])
        static let invalidName = "validation.invalid_name".localized
        static let pinMismatch = "validation.pin_mismatch".localized
    }
}
