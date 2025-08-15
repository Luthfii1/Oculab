//
//  ProfilePresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/11/24.
//

import Foundation

// MARK: - Main ProfilePresenter Class
class ProfilePresenter: ObservableObject {
    // MARK: - Dependencies
    private var interactor: ProfileInteractorProtocol
    private var authInteractor: AuthenticationInteractor

    // MARK: - Form Validation
    @Published var formValidation: FormValidationViewModel

    // MARK: - User Data
    @Published var user: User = .init()
    
    // MARK: - Password Fields with Validation
    @Published var oldPassword: String = AppValue.empty {
        didSet {
            validateOldPasswordField()
            isOldPasswordError = false
        }
    }

    @Published var inputPassword: String = AppValue.empty {
        didSet {
            validateNewPasswordField()
        }
    }

    @Published var confirmPassword: String = AppValue.empty {
        didSet {
            validateConfirmPasswordField()
        }
    }

    // MARK: - Validation Error States
    @Published var oldPasswordError: String = AppValue.empty
    @Published var newPasswordError: String = AppValue.empty
    @Published var confirmPasswordError: String = AppValue.empty
    
    // MARK: - Legacy Error States (for backward compatibility)
    @Published var isError: Bool = false
    @Published var isOldPasswordError: Bool = false {
        didSet {
            isOldPasswordError == true ? (descriptionOldPassword = AppTextAuthProfile.oldPasswordNotMatched) :
                (descriptionOldPassword = AppValue.empty)
        }
    }

    // MARK: - UI State
    @Published var descriptionPasswordConfirm: String = AppTextAuthProfile.descConfirmPassword
    @Published var descriptionOldPassword: String = AppValue.empty
    @Published var isLoading = false
    @Published var showSuccessPopup: Bool = false

    // MARK: - Computed Properties
    var saveChangesButtonText: String {
        return isLoading ? AppState.loading : AppAction.saveChanges
    }
    
    var isFormValid: Bool {
        return validatePasswordForm() && !isLoading
    }
    
    // MARK: - Initialization
    init(interactor: ProfileInteractorProtocol, authInteractor: AuthenticationInteractor) {
        self.formValidation = FormValidationViewModel()
        self.interactor = interactor
        self.authInteractor = authInteractor
        Task {
            await self.getUser()
        }
    }
}

// MARK: - Form Validation
extension ProfilePresenter {
    func validatePasswordForm() -> Bool {
        return formValidation.validatePasswordForm(
            currentPassword: oldPassword,
            newPassword: inputPassword,
            confirmPassword: confirmPassword
        )
    }
    
    private func validateOldPasswordField() {
        // Only show errors for non-empty fields or if form has been submitted
        if !oldPassword.isEmpty {
            let isValid = ValidationManager.shared.validateRequired(oldPassword, fieldName: ValidationFieldName.currentPassword.fieldName)
            oldPasswordError = isValid ? AppValue.empty : (formValidation.getError(for: .currentPassword) ?? AppValue.empty)
        } else {
            // Don't show "required" error for empty fields unless explicitly validating
            oldPasswordError = AppValue.empty
            formValidation.clearError(for: .currentPassword)
        }
    }
    
    private func validateNewPasswordField() {
        // Only show errors for non-empty fields
        if !inputPassword.isEmpty {
            let isValid = ValidationManager.shared.validatePassword(inputPassword, fieldName: ValidationFieldName.newPassword.fieldName)
            newPasswordError = isValid ? AppValue.empty : (formValidation.getError(for: .newPassword) ?? AppValue.empty)
        } else {
            // Don't show "required" error for empty fields
            newPasswordError = AppValue.empty
            formValidation.clearError(for: .newPassword)
        }
        
        // Re-validate confirmation if it's not empty
        if !confirmPassword.isEmpty {
            validateConfirmPasswordField()
        }
    }
    
    private func validateConfirmPasswordField() {
        if !confirmPassword.isEmpty {
            let isValid = ValidationManager.shared.validateFieldsMatch(inputPassword, confirmPassword, fieldName: ValidationFieldName.confirmPassword.fieldName)
            confirmPasswordError = isValid ? AppValue.empty : (formValidation.getError(for: .confirmPassword) ?? AppValue.empty)
            
            // Update legacy error states for backward compatibility
            if isValid {
                isError = false
                descriptionPasswordConfirm = AppTextAuthProfile.confirmPasswordSuccess
            } else {
                isError = true
                descriptionPasswordConfirm = confirmPasswordError
            }
        } else {
            confirmPasswordError = AppValue.empty
            isError = false
            descriptionPasswordConfirm = AppTextAuthProfile.descConfirmPassword
            formValidation.clearError(for: .confirmPassword)
        }
    }

    private func validatePasswords() {
        // Legacy method - now delegates to new validation methods
        validateNewPasswordField()
        validateConfirmPasswordField()
    }
    
    func isPasswordEditButtonEnabled() -> Bool {
        // Updated to use new validation system
        return isFormValid
    }
}

// MARK: - Password Management
extension ProfilePresenter {
    @MainActor
    func postEditPasswordWithValidation(authPresenter: AuthenticationPresenter) async {
        guard validatePasswordForm() else {
            return
        }
        
        formValidation.clearAllErrors()
        await postEditPassword(authPresenter: authPresenter)
    }

    @MainActor
    func postEditPassword(authPresenter: AuthenticationPresenter) async {
        guard !confirmPassword.isEmpty, !oldPassword.isEmpty else {
            descriptionOldPassword = AppTextAuthProfile.emptyPasswordError
            isOldPasswordError = true
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await interactor.editNewPassword(
                newPassword: confirmPassword,
                previousPassword: oldPassword)
            
            showSuccessPopup = true
            resetEditPassword()
        } catch {
            isOldPasswordError = true
            descriptionOldPassword = ErrorHandler.shared.handleError(error, context: .profile)
        }
    }
    
    func resetEditPassword() {
        oldPassword = AppValue.empty
        inputPassword = AppValue.empty
        confirmPassword = AppValue.empty
        isError = false
        descriptionPasswordConfirm = AppTextAuthProfile.descConfirmPassword
        descriptionOldPassword = AppValue.empty
        isOldPasswordError = false
        formValidation.clearAllErrors()
    }
}

// MARK: - User Management
extension ProfilePresenter {
    @MainActor
    func getUser() async {
        user = await authInteractor.getUserLocalData() ?? User()
    }

    @MainActor
    func logout() async {
        // Clear all UserDefaults except onboarding status
        for item in UserDefaultType.allCases where item != .hasSeenOnboarding {
            UserDefaults.standard.removeObject(forKey: item.rawValue)
        }
        
        // The AccountCheckerView will observe the isUserLoggedIn change
        // and automatically trigger state reset and navigation
    }
}

// MARK: - Navigation
extension ProfilePresenter {
    func navigateTo(_ destination: Router.Route) {
        Router.shared.navigateTo(destination)
    }
    
    func backToProfilePage() {
        showSuccessPopup = false
        Router.shared.popToRoot()
    }
}
