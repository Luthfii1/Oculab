//
//  ValidationFieldName+Extensions.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 13/08/2025.
//

import Foundation

// MARK: - Convenience Extensions

extension ValidationFieldName {
    
    /// Common field name combinations for forms
    struct FormFields {
        
        // MARK: - Authentication Forms
        static let login: [ValidationFieldName] = [.loginEmail, .loginPassword]
        
        // MARK: - User Management Forms
        static let userRegistration: [ValidationFieldName] = [.userName, .userEmail, .userRole]
        static let userProfile: [ValidationFieldName] = [.userName, .userEmail, .userPhone]
        
        // MARK: - Patient Forms
        static let patientBasic: [ValidationFieldName] = [.patientName, .patientNIK]
        static let patientComplete: [ValidationFieldName] = [
            .patientName, .patientNIK, .patientBPJS, 
            .patientPhone, .patientAddress, .patientDateOfBirth
        ]
        
        // MARK: - Medical Forms
        static let medicalRecord: [ValidationFieldName] = [
            .medicalRecordNumber, .diagnosis, .symptoms
        ]
        static let medicalHistory: [ValidationFieldName] = [
            .medicalHistory, .allergies, .medications
        ]
        
        // MARK: - Password Forms
        static let passwordChange: [ValidationFieldName] = [
            .currentPassword, .newPassword, .confirmPassword
        ]
        
        // MARK: - Examination Forms
        static let examination: [ValidationFieldName] = [
            .examinationDate, .examinationType, .examinationNotes
        ]
        
        // MARK: - Task Assignment Forms
        static let taskAssignment: [ValidationFieldName] = [
            .taskTitle, .taskDescription, .taskAssignee, .taskDueDate
        ]
        
        // MARK: - Video Recording Forms
        static let videoRecord: [ValidationFieldName] = [
            .videoTitle, .videoDescription, .videoQuality
        ]
    }
    
    /// Quick access to commonly used field names
    struct Quick {
        static let name = ValidationFieldName.name
        static let email = ValidationFieldName.email
        static let phone = ValidationFieldName.phone
        static let password = ValidationFieldName.newPassword
        static let confirmPassword = ValidationFieldName.confirmPassword
        static let nik = ValidationFieldName.patientNIK
        static let bpjs = ValidationFieldName.patientBPJS
        static let medicalRecord = ValidationFieldName.medicalRecord
    }
}

// MARK: - Array Extensions

extension Array where Element == ValidationFieldName {
    
    /// Get all field names as strings
    var fieldNames: [String] {
        return self.map { $0.fieldName }
    }
    
    /// Get all display names
    var displayNames: [String] {
        return self.map { $0.displayName }
    }
    
    /// Filter by category
    func fields(in category: ValidationFieldCategory) -> [ValidationFieldName] {
        return self.filter { $0.category == category }
    }
    
    /// Get medical fields only
    var medicalFields: [ValidationFieldName] {
        return self.filter { $0.isMedicalField }
    }
    
    /// Get authentication fields only
    var authenticationFields: [ValidationFieldName] {
        return self.filter { $0.isAuthenticationField }
    }
    
    /// Get fields that require special validation
    var specialValidationFields: [ValidationFieldName] {
        return self.filter { $0.requiresSpecialValidation }
    }
}

// MARK: - FormValidationViewModel Extensions

extension FormValidationViewModel {
    
    /// Convenience method to get errors for multiple fields
    func getErrors(for fieldNames: [ValidationFieldName]) -> [String: String] {
        var errors: [String: String] = [:]
        for fieldName in fieldNames {
            if let error = getError(for: fieldName) {
                errors[fieldName.fieldName] = error
            }
        }
        return errors
    }
    
    /// Check if any field in the array has errors
    func hasAnyError(for fieldNames: [ValidationFieldName]) -> Bool {
        return fieldNames.contains { hasError(for: $0) }
    }
    
    /// Clear errors for multiple fields
    func clearErrors(for fieldNames: [ValidationFieldName]) {
        fieldNames.forEach { clearError(for: $0) }
    }
    
    /// Validate multiple fields are not empty
    func validateRequired(fields: [(value: String, fieldName: ValidationFieldName)]) -> Bool {
        let validations = fields.map { field in
            return { self.validationManager.validateRequired(field.value, fieldName: field.fieldName.fieldName) }
        }
        return validateForm(validations: validations)
    }
    
    /// Batch validate different field types
    func validateMixedFields(
        names: [(value: String, fieldName: ValidationFieldName)] = [],
        emails: [(value: String, fieldName: ValidationFieldName)] = [],
        phones: [(value: String, fieldName: ValidationFieldName)] = [],
        passwords: [(value: String, fieldName: ValidationFieldName)] = [],
        required: [(value: String, fieldName: ValidationFieldName)] = []
    ) -> Bool {
        var validations: [() -> Bool] = []
        
        // Add name validations
        validations.append(contentsOf: names.map { field in
            return { self.validationManager.validateName(field.value, fieldName: field.fieldName.fieldName) }
        })
        
        // Add email validations
        validations.append(contentsOf: emails.map { field in
            return { self.validationManager.validateEmail(field.value, fieldName: field.fieldName.fieldName) }
        })
        
        // Add phone validations
        validations.append(contentsOf: phones.map { field in
            return { self.validationManager.validatePhoneNumber(field.value, fieldName: field.fieldName.fieldName) }
        })
        
        // Add password validations
        validations.append(contentsOf: passwords.map { field in
            return { self.validationManager.validatePassword(field.value, fieldName: field.fieldName.fieldName) }
        })
        
        // Add required validations
        validations.append(contentsOf: required.map { field in
            return { self.validationManager.validateRequired(field.value, fieldName: field.fieldName.fieldName) }
        })
        
        return validateForm(validations: validations)
    }
}

// MARK: - Presenter Extensions Helper

extension ValidationFieldName {
    
    /// Get the property name that would be used in presenter for error state
    var errorPropertyName: String {
        switch self {
        case .patientName: return "nameError"
        case .patientNIK: return "nikError"
        case .patientBPJS: return "bpjsError"
        case .userName: return "nameError"
        case .userEmail: return "emailError"
        case .userRole: return "roleError"
        case .currentPassword, .oldPassword: return "oldPasswordError"
        case .newPassword: return "newPasswordError"
        case .confirmPassword: return "confirmPasswordError"
        case .loginEmail: return "emailError"
        case .loginPassword: return "passwordError"
        default: return "\(self.rawValue.replacingOccurrences(of: "_", with: ""))Error"
        }
    }
}
