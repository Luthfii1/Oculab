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
    private var passwordRequestID: UUID?
    private var passwordSuccessSession: UploadQueueSession?
    private var passwordFormRevision = UUID()
    private var sessionObserver: NSObjectProtocol?

    // MARK: - Form Validation
    @Published var formValidation: FormValidationViewModel

    // MARK: - User Data
    @Published var user: User = .init()
    
    // MARK: - Password Fields with Validation
    @Published var oldPassword: String = AppValue.empty {
        didSet {
            clearGeneralFormError()
            ValidationManager.shared.clearError(for: ValidationFieldName.currentPassword.fieldName)
            validateOldPasswordField()
        }
    }

    @Published var inputPassword: String = AppValue.empty {
        didSet {
            clearGeneralFormError()
            validateNewPasswordField()
        }
    }

    @Published var confirmPassword: String = AppValue.empty {
        didSet {
            clearGeneralFormError()
            validateConfirmPasswordField()
        }
    }

    // MARK: - UI State
    @Published var confirmPasswordHint: String = AppTextAuthProfile.descConfirmPassword
    @Published var confirmPasswordHintIsError: Bool = false
    @Published var generalFormError: String = AppValue.empty
    @Published var isLoading = false
    @Published var showSuccessPopup: Bool = false
    @Published private(set) var hasAttemptedPasswordSubmit: Bool = false

    // MARK: - Computed Properties
    var saveChangesButtonText: String {
        return isLoading ? AppState.loading : AppAction.saveChanges
    }
    
    var isFormValid: Bool {
        !isLoading && isPasswordFormValidSilently()
    }
    
    // MARK: - Initialization
    init(interactor: ProfileInteractorProtocol, authInteractor: AuthenticationInteractor) {
        self.formValidation = FormValidationViewModel()
        self.interactor = interactor
        self.authInteractor = authInteractor
        sessionObserver = NotificationCenter.default.addObserver(
            forName: AuthSessionManager.sessionDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.resetEditPassword() }
        }
    }

    deinit {
        if let sessionObserver { NotificationCenter.default.removeObserver(sessionObserver) }
    }
}

// MARK: - Form Validation
extension ProfilePresenter {
    @MainActor
    func preparePasswordEditForm() {
        passwordFormRevision = UUID()
        passwordRequestID = nil
        passwordSuccessSession = nil
        isLoading = false
        showSuccessPopup = false
        hasAttemptedPasswordSubmit = false
        generalFormError = AppValue.empty
        confirmPasswordHint = AppTextAuthProfile.descConfirmPassword
        confirmPasswordHintIsError = false
        formValidation.clearErrors(for: [.currentPassword, .newPassword, .confirmPassword])
    }

    private func clearGeneralFormError() {
        guard !generalFormError.isEmpty else { return }
        generalFormError = AppValue.empty
    }

    private func isPasswordFormValidSilently() -> Bool {
        guard !oldPassword.isEmpty,
              !inputPassword.isEmpty,
              !confirmPassword.isEmpty else {
            return false
        }

        return ValidationManager.shared.meetsPasswordRequirements(inputPassword)
            && inputPassword != oldPassword
            && inputPassword == confirmPassword
    }

    @discardableResult
    func validatePasswordForm(showErrors: Bool) -> Bool {
        guard showErrors else {
            return isPasswordFormValidSilently()
        }

        return formValidation.validatePasswordForm(
            currentPassword: oldPassword,
            newPassword: inputPassword,
            confirmPassword: confirmPassword
        )
    }

    private func validateOldPasswordField() {
        guard hasAttemptedPasswordSubmit || !oldPassword.isEmpty else {
            ValidationManager.shared.clearError(for: ValidationFieldName.currentPassword.fieldName)
            return
        }

        if oldPassword.isEmpty {
            ValidationManager.shared.validateRequired(
                oldPassword,
                fieldName: ValidationFieldName.currentPassword.fieldName
            )
            return
        }

        ValidationManager.shared.clearError(for: ValidationFieldName.currentPassword.fieldName)
    }
    
    private func validateNewPasswordField() {
        guard hasAttemptedPasswordSubmit || !inputPassword.isEmpty else {
            ValidationManager.shared.clearError(for: ValidationFieldName.newPassword.fieldName)
            return
        }

        if inputPassword.isEmpty {
            ValidationManager.shared.validateRequired(
                inputPassword,
                fieldName: ValidationFieldName.newPassword.fieldName
            )
        } else {
            let passwordValid = ValidationManager.shared.validatePassword(
                inputPassword,
                fieldName: ValidationFieldName.newPassword.fieldName
            )

            if passwordValid {
                _ = ValidationManager.shared.validateNewPasswordDifferentFromCurrent(
                    inputPassword,
                    currentPassword: oldPassword,
                    fieldName: ValidationFieldName.newPassword.fieldName
                )
            }
        }

        if !confirmPassword.isEmpty {
            validateConfirmPasswordField()
        }
    }
    
    private func validateConfirmPasswordField() {
        guard hasAttemptedPasswordSubmit || !confirmPassword.isEmpty else {
            ValidationManager.shared.clearError(for: ValidationFieldName.confirmPassword.fieldName)
            confirmPasswordHint = AppTextAuthProfile.descConfirmPassword
            confirmPasswordHintIsError = false
            return
        }

        if confirmPassword.isEmpty {
            ValidationManager.shared.validateRequired(
                confirmPassword,
                fieldName: ValidationFieldName.confirmPassword.fieldName
            )
            confirmPasswordHint = AppTextAuthProfile.descConfirmPassword
            confirmPasswordHintIsError = true
            return
        }

        let isValid = ValidationManager.shared.validateFieldsMatch(
            inputPassword,
            confirmPassword,
            fieldName: ValidationFieldName.confirmPassword.fieldName
        )

        if isValid {
            confirmPasswordHint = AppTextAuthProfile.confirmPasswordSuccess
            confirmPasswordHintIsError = false
        } else {
            confirmPasswordHint = ValidationManager.shared.getError(
                for: ValidationFieldName.confirmPassword.fieldName
            ) ?? AppTextAuthProfile.confirmPasswordError
            confirmPasswordHintIsError = true
        }
    }
}

// MARK: - Password Management
extension ProfilePresenter {
    @MainActor
    func postEditPasswordWithValidation(authPresenter: AuthenticationPresenter) async {
        guard !isLoading, passwordRequestID == nil else { return }
        hasAttemptedPasswordSubmit = true
        generalFormError = AppValue.empty

        guard validatePasswordForm(showErrors: true) else {
            validateNewPasswordField()
            validateConfirmPasswordField()
            return
        }
        
        await postEditPassword(authPresenter: authPresenter)
    }

    @MainActor
    func postEditPassword(authPresenter: AuthenticationPresenter) async {
        guard !isLoading, passwordRequestID == nil else { return }
        guard let session = AuthSessionManager.uploadQueueSession else {
            generalFormError = ErrorHandler.shared.handleError(URLError(.userAuthenticationRequired), context: .profile)
            return
        }
        let requestID = UUID()
        let revision = passwordFormRevision
        passwordRequestID = requestID
        passwordSuccessSession = nil
        showSuccessPopup = false
        isLoading = true
        defer {
            if passwordRequestID == requestID {
                passwordRequestID = nil
                isLoading = false
            }
        }
        
        do {
            let response = try await interactor.editNewPassword(
                newPassword: inputPassword,
                previousPassword: oldPassword
            )
            guard !Task.isCancelled, session == AuthSessionManager.uploadQueueSession,
                  passwordRequestID == requestID, passwordFormRevision == revision,
                  response.userId.lowercased() == session.ownerUserId else { return }
            resetEditPassword()
            passwordSuccessSession = session
            showSuccessPopup = true
        } catch {
            guard !Task.isCancelled, !(error is CancellationError), session == AuthSessionManager.uploadQueueSession,
                  passwordRequestID == requestID, passwordFormRevision == revision else { return }
            handlePasswordChangeError(error)
        }
    }

    private func handlePasswordChangeError(_ error: Error) {
        switch error {
        case let NetworkError.apiError(apiResponse, _):
            applyPasswordAPIError(apiResponse.data)

        default:
            generalFormError = ErrorHandler.shared.handleError(error, context: .profile)
        }
    }

    private func applyPasswordAPIError(_ apiError: ApiErrorData) {
        let description = apiError.description
        let normalized = description.lowercased()

        if apiError.errorType == "VALIDATION_ERROR" {
            if normalized.contains("previous password") || normalized.contains("incorrect") {
                ValidationManager.shared.setError(
                    AppTextAuthEditPassword.currentPasswordIncorrect,
                    for: ValidationFieldName.currentPassword.fieldName
                )
                return
            }

            if normalized.contains("different from the current") {
                ValidationManager.shared.setError(
                    AppTextAuthEditPassword.newPasswordSameAsCurrent,
                    for: ValidationFieldName.newPassword.fieldName
                )
                return
            }
        }

        if normalized.contains("previous password") || normalized.contains("incorrect") {
            ValidationManager.shared.setError(
                AppTextAuthEditPassword.currentPasswordIncorrect,
                for: ValidationFieldName.currentPassword.fieldName
            )
            return
        }

        generalFormError = description.isEmpty ? AppTextAuthEditPassword.updateFailed : description
    }
    
    @MainActor
    func resetEditPassword() {
        passwordFormRevision = UUID()
        passwordRequestID = nil
        passwordSuccessSession = nil
        isLoading = false
        showSuccessPopup = false
        oldPassword = AppValue.empty
        inputPassword = AppValue.empty
        confirmPassword = AppValue.empty
        hasAttemptedPasswordSubmit = false
        generalFormError = AppValue.empty
        confirmPasswordHint = AppTextAuthProfile.descConfirmPassword
        confirmPasswordHintIsError = false
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
    func logout(authPresenter: AuthenticationPresenter) async {
        await authPresenter.performLogout()
    }
}

// MARK: - Navigation
extension ProfilePresenter {
    func navigateTo(_ destination: Router.Route) {
        Router.shared.navigateTo(destination)
    }
    
    @MainActor
    func backToProfilePage() {
        let successSession = passwordSuccessSession
        showSuccessPopup = false
        passwordSuccessSession = nil
        guard let successSession, successSession == AuthSessionManager.uploadQueueSession else { return }
        // Keep the session check and navigation mutation in the same main-actor
        // turn; Router.popToRoot queues a block that could otherwise run after login.
        let router = Router.shared
        if !router.path.isEmpty { router.path.removeLast(router.path.count) }
        router.currentRoute = nil
        router.endTaskAssignmentFlow()
    }
}
