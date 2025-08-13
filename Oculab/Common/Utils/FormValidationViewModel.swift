//
//  FormValidationViewModel.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 12/08/2025.
//

import Foundation
import SwiftUI
import Combine

/// View model to handle form validation state and logic
@MainActor
class FormValidationViewModel: ObservableObject {
    
    @Published var isFormValid: Bool = false
    @Published var validationErrors: [String: String] = [:]
    
    private let validationManager = ValidationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to validation manager errors
        validationManager.$errors
            .receive(on: DispatchQueue.main)
            .assign(to: \.validationErrors, on: self)
            .store(in: &cancellables)
        
        // Update form validity when errors change
        validationManager.$errors
            .map { $0.isEmpty }
            .receive(on: DispatchQueue.main)
            .assign(to: \.isFormValid, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Validation Methods
    
    /// Validate all form fields at once
    func validateForm(validations: [() -> Bool]) -> Bool {
        return validationManager.validateFields(validations)
    }
    
    /// Check if specific field has error
    func hasError(for fieldName: ValidationFieldName) -> Bool {
        return validationManager.hasError(for: fieldName.fieldName)
    }
    
    /// Get error message for specific field
    func getError(for fieldName: ValidationFieldName) -> String? {
        return validationManager.getError(for: fieldName.fieldName)
    }
    
    /// Clear all validation errors
    func clearAllErrors() {
        validationManager.clearAllErrors()
    }
    
    /// Clear error for specific field
    func clearError(for fieldName: ValidationFieldName) {
        validationManager.clearError(for: fieldName.fieldName)
    }
    
    // MARK: - String-based methods (Legacy support)
    
    /// Check if specific field has error (string-based for legacy support)
    func hasError(for fieldName: String) -> Bool {
        return validationManager.hasError(for: fieldName)
    }
    
    /// Get error message for specific field (string-based for legacy support)
    func getError(for fieldName: String) -> String? {
        return validationManager.getError(for: fieldName)
    }
    
    /// Clear error for specific field (string-based for legacy support)
    func clearError(for fieldName: String) {
        validationManager.clearError(for: fieldName)
    }
    
    // MARK: - Form-specific Validation
    
    /// Validate patient form fields
    func validatePatientForm(name: String, nik: String, bpjs: String? = nil) -> Bool {
        let validations: [() -> Bool] = [
            { self.validationManager.validateName(name, fieldName: ValidationFieldName.patientName.fieldName) },
            { self.validationManager.validateNIK(nik, fieldName: ValidationFieldName.patientNIK.fieldName) },
            { 
                if let bpjs = bpjs, !bpjs.isEmpty {
                    return self.validationManager.validateWithRules(bpjs, fieldName: ValidationFieldName.patientBPJS.fieldName, rules: [
                        .numbersOnly(),
                        .minLength(13),
                        .maxLength(13)
                    ])
                }
                return true
            }
        ]
        
        return validateForm(validations: validations)
    }
    
    /// Validate user registration form
    func validateUserForm(name: String, email: String, role: String) -> Bool {
        let validations: [() -> Bool] = [
            { self.validationManager.validateName(name, fieldName: ValidationFieldName.userName.fieldName) },
            { self.validationManager.validateEmail(email, fieldName: ValidationFieldName.userEmail.fieldName) },
            { self.validationManager.validateRequired(role, fieldName: ValidationFieldName.userRole.fieldName) }
        ]
        
        return validateForm(validations: validations)
    }
    
    /// Validate authentication form
    func validateLoginForm(email: String, password: String) -> Bool {
        let validations: [() -> Bool] = [
            { self.validationManager.validateEmail(email, fieldName: ValidationFieldName.loginEmail.fieldName) },
            { self.validationManager.validateRequired(password, fieldName: ValidationFieldName.loginPassword.fieldName) }
        ]
        
        return validateForm(validations: validations)
    }
    
    /// Validate password change form
    func validatePasswordForm(currentPassword: String, newPassword: String, confirmPassword: String) -> Bool {
        let validations: [() -> Bool] = [
            { self.validationManager.validateRequired(currentPassword, fieldName: ValidationFieldName.currentPassword.fieldName) },
            { self.validationManager.validatePassword(newPassword, fieldName: ValidationFieldName.newPassword.fieldName) },
            { self.validationManager.validateFieldsMatch(newPassword, confirmPassword, fieldName: ValidationFieldName.confirmPassword.fieldName) }
        ]
        
        return validateForm(validations: validations)
    }
    
    // MARK: - Medical Validation Helpers
    
    /// Validate medical record number with custom rules
    func validateMedicalRecord(_ mrn: String, fieldName: ValidationFieldName = .medicalRecord) -> Bool {
        return validationManager.validateMedicalRecordNumber(mrn, fieldName: fieldName.fieldName)
    }
    
    /// Validate date of birth
    func validateDateOfBirth(_ date: Date?, fieldName: ValidationFieldName = .dateOfBirth) -> Bool {
        return validationManager.validateDate(
            date,
            fieldName: fieldName.fieldName,
            allowFuture: false,
            allowPast: true,
            minimumAge: 0,
            maximumAge: 150
        )
    }
    
    /// Validate age input
    func validateAge(_ age: Int?, fieldName: ValidationFieldName = .age) -> Bool {
        return validationManager.validateAge(age, fieldName: fieldName.fieldName, minAge: 0, maxAge: 150)
    }
    
    // MARK: - Real-time Validation
    
    /// Enable real-time validation for a field
    func setupRealtimeValidation<T: Publisher>(
        for publisher: T,
        fieldName: ValidationFieldName,
        validationType: ValidationType
    ) where T.Output == String, T.Failure == Never {
        
        publisher
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self = self, !value.isEmpty else { return }
                
                let fieldNameString = fieldName.fieldName
                
                switch validationType {
                case .email:
                    self.validationManager.validateEmail(value, fieldName: fieldNameString)
                case .password:
                    self.validationManager.validatePassword(value, fieldName: fieldNameString)
                case .name:
                    self.validationManager.validateName(value, fieldName: fieldNameString)
                case .phone:
                    self.validationManager.validatePhoneNumber(value, fieldName: fieldNameString)
                case .nik:
                    self.validationManager.validateNIK(value, fieldName: fieldNameString)
                case .medicalRecord:
                    self.validationManager.validateMedicalRecordNumber(value, fieldName: fieldNameString)
                case .required:
                    self.validationManager.validateRequired(value, fieldName: fieldNameString)
                default:
                    break
                }
            }
            .store(in: &self.cancellables)
    }
    
    /// Enable real-time validation for a field (legacy string-based)
    func setupRealtimeValidation<T: Publisher>(
        for publisher: T,
        fieldName: String,
        validationType: ValidationType
    ) where T.Output == String, T.Failure == Never {
        
        publisher
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self = self, !value.isEmpty else { return }
                
                switch validationType {
                case .email:
                    self.validationManager.validateEmail(value, fieldName: fieldName)
                case .password:
                    self.validationManager.validatePassword(value, fieldName: fieldName)
                case .name:
                    self.validationManager.validateName(value, fieldName: fieldName)
                case .phone:
                    self.validationManager.validatePhoneNumber(value, fieldName: fieldName)
                case .nik:
                    self.validationManager.validateNIK(value, fieldName: fieldName)
                case .medicalRecord:
                    self.validationManager.validateMedicalRecordNumber(value, fieldName: fieldName)
                case .required:
                    self.validationManager.validateRequired(value, fieldName: fieldName)
                default:
                    break
                }
            }
            .store(in: &self.cancellables)
    }
}

// MARK: - Form State Helper

/// Helper struct to manage form submission state
struct FormSubmissionState {
    var isSubmitting: Bool = false
    var isValid: Bool = false
    var hasAttemptedSubmission: Bool = false
    
    mutating func startSubmission() {
        isSubmitting = true
    }
    
    mutating func endSubmission(success: Bool) {
        isSubmitting = false
        hasAttemptedSubmission = true
        if success {
            reset()
        }
    }
    
    mutating func reset() {
        isSubmitting = false
        hasAttemptedSubmission = false
    }
}
