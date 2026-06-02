//
//  ValidationManager.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 12/08/2025.
//

import Foundation
import SwiftUI

/// Comprehensive validation system for all form inputs
class ValidationManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var errors: [String: String] = [:]
    @Published var isValidating: Bool = false
    
    // MARK: - Shared instance (auth, profile, patient modules)
    static let shared = ValidationManager()

    init() {}
    
    // MARK: - Validation Rules
    
    /// Validates an email address
    func validateEmail(_ email: String, fieldName: String = "email") -> Bool {
        clearError(for: fieldName)
        
        guard !email.isEmpty else {
            setError("email_required".localized, for: fieldName)
            return false
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: email) else {
            setError("email_invalid".localized, for: fieldName)
            return false
        }
        
        return true
    }
    
    /// Validates a password with customizable requirements
    func validatePassword(_ password: String, 
                         fieldName: String = "password",
                         minLength: Int = 8,
                         requireUppercase: Bool = true,
                         requireLowercase: Bool = true,
                         requireNumbers: Bool = false,
                         requireSpecialChars: Bool = false) -> Bool {
        clearError(for: fieldName)
        
        guard !password.isEmpty else {
            setError("password_required".localized, for: fieldName)
            return false
        }
        
        guard password.count >= minLength else {
            setError(String(format: "password_min_length".localized, minLength), for: fieldName)
            return false
        }
        
        if requireUppercase && !password.contains(where: { $0.isUppercase }) {
            setError("password_uppercase_required".localized, for: fieldName)
            return false
        }
        
        if requireLowercase && !password.contains(where: { $0.isLowercase }) {
            setError("password_lowercase_required".localized, for: fieldName)
            return false
        }
        
        if requireNumbers && !password.contains(where: { $0.isNumber }) {
            setError("password_number_required".localized, for: fieldName)
            return false
        }
        
        if requireSpecialChars && !password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) }) {
            setError("password_special_char_required".localized, for: fieldName)
            return false
        }
        
        return true
    }
    
    /// Checks password rules without mutating validation error state.
    func meetsPasswordRequirements(
        _ password: String,
        minLength: Int = 8,
        requireUppercase: Bool = true,
        requireLowercase: Bool = true,
        requireNumbers: Bool = false,
        requireSpecialChars: Bool = false
    ) -> Bool {
        guard !password.isEmpty, password.count >= minLength else { return false }

        if requireUppercase && !password.contains(where: { $0.isUppercase }) {
            return false
        }

        if requireLowercase && !password.contains(where: { $0.isLowercase }) {
            return false
        }

        if requireNumbers && !password.contains(where: { $0.isNumber }) {
            return false
        }

        if requireSpecialChars && !password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) }) {
            return false
        }

        return true
    }
    
    /// Validates a PIN code
    func validatePIN(_ pin: String, fieldName: String = "pin", expectedLength: Int = 4) -> Bool {
        clearError(for: fieldName)
        
        guard !pin.isEmpty else {
            setError("pin_required".localized, for: fieldName)
            return false
        }
        
        guard pin.count == expectedLength else {
            setError(String(format: "pin_length_invalid".localized, expectedLength), for: fieldName)
            return false
        }
        
        guard pin.allSatisfy(\.isNumber) else {
            setError("pin_numbers_only".localized, for: fieldName)
            return false
        }
        
        return true
    }
    
    /// Validates a phone number
    func validatePhoneNumber(_ phone: String, fieldName: String = "phone") -> Bool {
        clearError(for: fieldName)
        
        guard !phone.isEmpty else {
            setError("phone_required".localized, for: fieldName)
            return false
        }
        
        // Remove all non-numeric characters for validation
        let numericPhone = phone.filter { $0.isNumber }
        
        guard numericPhone.count >= 10 && numericPhone.count <= 15 else {
            setError("phone_invalid_length".localized, for: fieldName)
            return false
        }
        
        return true
    }
    
    /// Validates a name field
    func validateName(_ name: String, fieldName: String = "name", minLength: Int = 2) -> Bool {
        clearError(for: fieldName)
        
        guard !name.isEmpty else {
            setError("name_required".localized, for: fieldName)
            return false
        }
        
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).count >= minLength else {
            setError(String(format: "name_min_length".localized, minLength), for: fieldName)
            return false
        }
        
        // Check for valid characters (letters, spaces, hyphens, apostrophes)
        let validNameRegex = "^[a-zA-Z\\s\\-\\']+$"
        let namePredicate = NSPredicate(format: "SELF MATCHES %@", validNameRegex)
        
        guard namePredicate.evaluate(with: name) else {
            setError("name_invalid_characters".localized, for: fieldName)
            return false
        }
        
        return true
    }
    
    func validateNewPasswordDifferentFromCurrent(
        _ newPassword: String,
        currentPassword: String,
        fieldName: String = ValidationFieldName.newPassword.fieldName
    ) -> Bool {
        clearError(for: fieldName)

        guard !newPassword.isEmpty, !currentPassword.isEmpty else {
            return true
        }

        guard newPassword != currentPassword else {
            setError("auth.edit_password.new_password_same_as_current".localized, for: fieldName)
            return false
        }

        return true
    }

    /// Validates that two fields match (e.g., password confirmation)
    func validateFieldsMatch(
        _ field1: String,
        _ field2: String,
        fieldName: String = "confirmation",
        requireBothFields: Bool = false
    ) -> Bool {
        clearError(for: fieldName)

        if field2.isEmpty {
            if requireBothFields {
                setError("password_required".localized, for: fieldName)
                return false
            }
            return true
        }

        guard field1 == field2 else {
            setError("fields_do_not_match".localized, for: fieldName)
            return false
        }

        return true
    }
    
    /// Validates an Indonesian NIK (National Identity Number)
    func validateNIK(_ nik: String, fieldName: String = "nik") -> Bool {
        clearError(for: fieldName)
        
        guard !nik.isEmpty else {
            setError("validation.nik_required".localized, for: fieldName)
            return false
        }
        
        guard nik.count == 16 else {
            setError("validation.nik_invalid_length".localized, for: fieldName)
            return false
        }
        
        guard nik.allSatisfy(\.isNumber) else {
            setError("validation.nik_numbers_only".localized, for: fieldName)
            return false
        }
        
        return true
    }
    
    /// Validates medical record number format
    func validateMedicalRecordNumber(_ mrn: String, fieldName: String = "medical_record") -> Bool {
        clearError(for: fieldName)
        
        guard !mrn.isEmpty else {
            setError("validation.medical_record_required".localized, for: fieldName)
            return false
        }
        
        // Typically 6-12 alphanumeric characters
        guard mrn.count >= 6 && mrn.count <= 12 else {
            setError("validation.medical_record_invalid_length".localized, for: fieldName)
            return false
        }
        
        guard mrn.allSatisfy({ $0.isLetter || $0.isNumber }) else {
            setError("validation.medical_record_alphanumeric_only".localized, for: fieldName)
            return false
        }
        
        return true
    }
    
    /// Validates age input
    func validateAge(_ age: Int?, fieldName: String = "age", minAge: Int = 0, maxAge: Int = 150) -> Bool {
        clearError(for: fieldName)
        
        guard let age = age else {
            setError("validation.age_required".localized, for: fieldName)
            return false
        }
        
        guard age >= minAge else {
            setError(String(format: "validation.age_too_young".localized, minAge), for: fieldName)
            return false
        }
        
        guard age <= maxAge else {
            setError(String(format: "validation.age_too_old".localized, maxAge), for: fieldName)
            return false
        }
        
        return true
    }
    
    /// Validates a required field (not empty)
    func validateRequired(_ value: String, fieldName: String) -> Bool {
        clearError(for: fieldName)
        
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            setError("field_required".localized, for: fieldName)
            return false
        }
        
        return true
    }
    
    /// Validates a date field
    func validateDate(_ date: Date?, fieldName: String = "date", 
                     allowFuture: Bool = true, 
                     allowPast: Bool = true,
                     minimumAge: Int? = nil,
                     maximumAge: Int? = nil) -> Bool {
        clearError(for: fieldName)
        
        guard let date = date else {
            setError("date_required".localized, for: fieldName)
            return false
        }
        
        let now = Date()
        
        if !allowFuture && date > now {
            setError("date_future_not_allowed".localized, for: fieldName)
            return false
        }
        
        if !allowPast && date < now {
            setError("date_past_not_allowed".localized, for: fieldName)
            return false
        }
        
        let calendar = Calendar.current
        
        if let minimumAge = minimumAge {
            let ageComponents = calendar.dateComponents([.year], from: date, to: now)
            if let age = ageComponents.year, age < minimumAge {
                setError(String(format: "minimum_age_required".localized, minimumAge), for: fieldName)
                return false
            }
        }
        
        if let maximumAge = maximumAge {
            let ageComponents = calendar.dateComponents([.year], from: date, to: now)
            if let age = ageComponents.year, age > maximumAge {
                setError(String(format: "maximum_age_exceeded".localized, maximumAge), for: fieldName)
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Validation Helpers
    
    /// Validates multiple fields at once
    func validateFields(_ validations: [() -> Bool]) -> Bool {
        isValidating = true
        defer { isValidating = false }
        
        let results = validations.map { $0() }
        return results.allSatisfy { $0 }
    }
    
    /// Checks if a specific field has errors
    func hasError(for fieldName: String) -> Bool {
        return errors[fieldName] != nil
    }
    
    /// Gets the error message for a field
    func getError(for fieldName: String) -> String? {
        return errors[fieldName]
    }
    
    /// Sets an error for a field
    func setError(_ message: String, for fieldName: String) {
        DispatchQueue.main.async {
            self.errors[fieldName] = message
        }
    }
    
    /// Clears the error for a field
    func clearError(for fieldName: String) {
        DispatchQueue.main.async {
            self.errors.removeValue(forKey: fieldName)
        }
    }
    
    /// Clears all errors
    func clearAllErrors() {
        DispatchQueue.main.async {
            self.errors.removeAll()
        }
    }
    
    /// Checks if the form has any errors
    var hasAnyErrors: Bool {
        return !errors.isEmpty
    }
    
    /// Gets all error messages
    var allErrorMessages: [String] {
        return Array(errors.values)
    }
}

// MARK: - Validation Rules Extension

extension ValidationManager {
    
    /// Custom validation rule
    struct ValidationRule {
        let check: (String) -> Bool
        let errorMessage: String
        
        init(_ check: @escaping (String) -> Bool, errorMessage: String) {
            self.check = check
            self.errorMessage = errorMessage
        }
    }
    
    /// Validates a field with custom rules
    func validateWithRules(_ value: String, fieldName: String, rules: [ValidationRule]) -> Bool {
        clearError(for: fieldName)
        
        for rule in rules {
            if !rule.check(value) {
                setError(rule.errorMessage, for: fieldName)
                return false
            }
        }
        
        return true
    }
}

// MARK: - Common Validation Rules

extension ValidationManager.ValidationRule {
    
    static func minLength(_ length: Int) -> ValidationManager.ValidationRule {
        return ValidationManager.ValidationRule(
            { $0.count >= length },
            errorMessage: String(format: "min_length_required".localized, length)
        )
    }
    
    static func maxLength(_ length: Int) -> ValidationManager.ValidationRule {
        return ValidationManager.ValidationRule(
            { $0.count <= length },
            errorMessage: String(format: "max_length_exceeded".localized, length)
        )
    }
    
    static func notEmpty() -> ValidationManager.ValidationRule {
        return ValidationManager.ValidationRule(
            { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            errorMessage: "field_required".localized
        )
    }
    
    static func numbersOnly() -> ValidationManager.ValidationRule {
        return ValidationManager.ValidationRule(
            { $0.allSatisfy(\.isNumber) },
            errorMessage: "numbers_only".localized
        )
    }
    
    static func lettersOnly() -> ValidationManager.ValidationRule {
        return ValidationManager.ValidationRule(
            { $0.allSatisfy(\.isLetter) },
            errorMessage: "letters_only".localized
        )
    }
    
    static func alphanumeric() -> ValidationManager.ValidationRule {
        return ValidationManager.ValidationRule(
            { $0.allSatisfy { $0.isLetter || $0.isNumber } },
            errorMessage: "alphanumeric_only".localized
        )
    }
}
