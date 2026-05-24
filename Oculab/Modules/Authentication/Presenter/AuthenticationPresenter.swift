//
//  AuthenticationPresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 06/11/24.
//

import Foundation
import LocalAuthentication
import SwiftUI
import Combine

enum PinMode {
    case create, revalidate, authenticate, changePIN, forgetPin
}

// MARK: - Main AuthenticationPresenter Class
class AuthenticationPresenter: ObservableObject {
    // MARK: - Published Properties
    // UI State
    @Published var isSplashScreenVisible = true
    @Published var description: String = AppValue.empty
    @Published var textColor: Color = AppColors.slate900
    @Published var pinColor: Color = AppColors.purple500
    @Published var isLoading = false
    @Published var isKeyboardVisible = false
    @Published var isOpeningApp = false
    
    // Form Validation  
    @Published var formValidation: FormValidationViewModel
    
    // Authentication State
    @Published var user: User = .init()
    @Published var isPinAuthorized: Bool = false
    @Published var isSuccess: Bool = false
    @Published var isLogin: Bool = false
    @Published var email = AppValue.empty
    @Published var password = AppValue.empty

    // Registration State
    @Published var registerFullName: String = AppValue.empty
    @Published var registerEmail: String = AppValue.empty
    @Published var registerHealthFacilityName: String = AppValue.empty
    @Published var registerHealthFacilityType: HealthFacilityType? = nil
    @Published var showRegisterSuccessAlert: Bool = false
    @Published var registerSuccessMessage: String = AppValue.empty
    @Published var isChoosingRegistrationType: Bool = true

    // PIN Management State
    @Published var firstPin = AppValue.empty
    @Published var secondPin = AppValue.empty
    @Published var inputPin = AppValue.empty {
        didSet {
            if !inputPin.isEmpty {
                isError = false
            }
        }
    }
    @Published var oldAccessPin = AppValue.empty
    @Published var newAccessPin = AppValue.empty
    @Published var isAccessPinChangeInProgress = false
    @Published var showAccessPinSuccessPopup = false
    @Published var showForgetPinPopup = false
    @Published var descriptionPIN: String = AppValue.empty
    @Published var state: PinMode = .authenticate {
        didSet {
            setDescriptionPIN()
        }
    }
    
    // Biometric Authentication
    @Published var isFaceIdAvailable: Bool = false
    @Published var isFaceIdEnabledFromUserDefaults: Bool = UserDefaults.standard.bool(forKey: UserDefaultType.isFaceIdEnabled.rawValue)
    
    // Error Handling
    @Published var isError: Bool = false {
        didSet {
            updateUIForErrorState()
        }
    }
    @Published var errorMessage: String = AppValue.empty
    
    // MARK: - Constants & Dependencies
    let numbers = AppConstants.pinNumbers
    private var interactor: AuthenticationInteractor
    weak var appStateManager: AppStateManager?

    // MARK: - Computed Properties
    var isFilled: Bool {
        return isLoginFormValidAndFilled() && !isLoading
    }

    var isRegisterFormValid: Bool {
        !registerFullName.isEmpty &&
        !registerEmail.isEmpty &&
        !registerHealthFacilityName.isEmpty &&
        registerHealthFacilityType != nil &&
        !formValidation.hasError(for: .registerFullName) &&
        !formValidation.hasError(for: .registerEmail) &&
        !formValidation.hasError(for: .registerHealthFacilityName)
    }
    
    var isFormValid: () -> Bool = {
        return false // Will be updated in init
    }
    
    var loginButtonText: String {
        isLoading ? AppState.loading : AppTextAuthLogin.buttonText
    }
    
    var registerButtonText: String {
        isLoading ? AppState.loading : AppTextAuthRegister.submitButton
    }
    
    var isDropdownOfficerDisabled: Bool {
        return user.role == .LAB && user.businessModel == .B2C
    }

    // MARK: - Initialization
    init(interactor: AuthenticationInteractor) {
        self.interactor = interactor
        self.formValidation = FormValidationViewModel()
        self.setupFormValidation()
        // setDescriptionPIN() will be called by state's didSet during initialization
    }
}

// MARK: - Authentication Methods
extension AuthenticationPresenter {

    @MainActor
    func handleRegister() async {
        isLoading = true
        defer { isLoading = false }
        // Validate form before sending
        guard isRegisterFormValidAndFilled() else {
            isError = true
            errorMessage = AppTextAuthRegister.validationErrorFillAllFields
            return
        }
        do {
            let _ = try await interactor.registerUser(
                name: registerFullName,
                email: registerEmail,
                healthFacilityName: registerHealthFacilityName,
                healthFacilityType: registerHealthFacilityType?.rawValue ?? AppValue.empty
            )

            showRegisterSuccessAlert = true
            registerSuccessMessage = AppTextAuthRegister.successRegisterMessage
        } catch {
            isError = true
            errorMessage = ErrorHandler.shared.handleError(error, context: .login)
        }
    }
    
    @MainActor
    func updateLoadingState(_ loading: Bool) {
        isLoading = loading
    }
    
    @MainActor
    func handleLogin() async -> Bool {
        // Validate all required fields
        let isValid = await formValidation.validateBatch(
            fields: ValidationFieldName.FormFields.login,
            values: [
                .loginEmail: email,
                .loginPassword: password
            ]
        )

        // Check if form is valid
        guard isValid && isFormValid() else {
            return false
        }
        
        // Clear any previous general errors since validation passed
        isError = false
        
        // Proceed with login
        let loginSuccess = await login()
        
        if loginSuccess {
            await getAccountById()
        } else {
            isError = true
            // Use the backend error message if available, otherwise use generic message
            if !errorMessage.isEmpty {
                description = errorMessage
            } else {
                description = AppTextAuthLogin.loginFailedText
            }
        }
        
        return loginSuccess
    }
    
    @MainActor
    private func login() async -> Bool {
        defer { isLoading = false }
        isLoading = true
        
        do {
            let response = try await interactor.login(
                email: email,
                password: password
            )
            
            // Tokens are stored automatically in the login method
            isSuccess = true
            
            return true
        } catch {
            isError = true
            errorMessage = ErrorHandler.shared.handleError(error, context: .login)
            
            return false
        }
    }
    
    @MainActor
    func getAccountById() async {
        do {
            let account = try await interactor.getAccountById()
            
            // Store the user data locally
            await interactor.updateUserLocalData(user: account)
            
            user = account
            isLogin = true
            
            // Clear any PIN state
            inputPin = AppValue.empty
            firstPin = AppValue.empty
            secondPin = AppValue.empty
            oldAccessPin = AppValue.empty
            newAccessPin = AppValue.empty
            isAccessPinChangeInProgress = false

            if account.accessPin == nil {
                // User needs to create PIN
                state = .create
                isPinAuthorized = false
                appStateManager?.setRequiresPin(hasExistingPin: false)
            } else {
                // User needs to authenticate with existing PIN
                state = .authenticate
                isPinAuthorized = false
                appStateManager?.setRequiresPin(hasExistingPin: true)
            }
            
        } catch {
            errorMessage = ErrorHandler.shared.handleError(error, context: .login)
            
            // Handle error and ensure user goes back to login
            isPinAuthorized = false
            clearLoginState()
            appStateManager?.setUnauthenticated()
            
            isError = true
        }
    }
}

// MARK: - PIN Management
extension AuthenticationPresenter {
    /// Constant-time comparison to avoid leaking PIN content via early-exit timing.
    private static func constantTimeEquals(_ a: String, _ b: String) -> Bool {
        let aBytes = Array(a.utf8)
        let bBytes = Array(b.utf8)
        guard aBytes.count == bBytes.count else { return false }
        var diff: UInt8 = 0
        for i in 0..<aBytes.count {
            diff |= aBytes[i] ^ bBytes[i]
        }
        return diff == 0
    }

    @MainActor
    func isValidPin() async -> Bool {
        // For PIN change flow, we should check against oldAccessPin, not the stored PIN
        if isAccessPinChangeInProgress {
            if !Self.constantTimeEquals(oldAccessPin, inputPin) {
                description = AppTextAuthCompPin.invalidPinText
                isError = true
                return false
            }
        } else {
            // Normal authentication - check against stored PIN
            let storedPin = await interactor.getUserLocalData()?.accessPin ?? AppValue.empty
            if !Self.constantTimeEquals(storedPin, inputPin) {
                description = AppTextAuthCompPin.invalidPinText
                isError = true
                return false
            }
        }

        return true
    }
    
    func updateInputPin(newPin: String) {
        inputPin = newPin
        isError = false
        description = AppValue.empty
    }
    
    @MainActor
    func handlePinInput(_ pin: String) async {
        guard ValidationHelpers.isValidPIN(pin) else { 
            return 
        }

        switch state {
        case .create:
            firstPin = pin
            inputPin = AppValue.empty
            state = .revalidate
            Router.shared.navigateTo(.userAccessPin(state: .revalidate))

        case .revalidate:
            secondPin = pin

            if revalidatePinMatched() {
                if isAccessPinChangeInProgress {
                    // This is part of PIN change flow - call the PIN update API
                    newAccessPin = secondPin
                    await editAccessPin()
                } else {
                    // This is initial PIN setup - just update locally and authorize
                    user.accessPin = secondPin
                    await createAccessPin()
                    await interactor.updateUserLocalData(user: user)
                    // State transition handled by AccountCheckerView onChange
                    appStateManager?.initializationState = .createFaceId
                    Router.shared.popToRoot()
                }
            } else {
                inputPin = AppValue.empty
                isError = true
                // Error description is already set in revalidatePinMatched()
            }

        case .authenticate:
            if await self.isValidPin() {
                if isFirstTimeLoggedIn() {
                    appStateManager?.initializationState = .createFaceId
                    Router.shared.popToRoot()
                } else {
                    isPinAuthorized = true
                }
                // set false for first time login
                UserDefaults.standard.set(false, forKey: UserDefaultType.firstTimeLogin.rawValue)
                // State transition handled by AccountCheckerView onChange
            } else {
                inputPin = AppValue.empty
                // Error description is already set in isValidPin()
            }

        case .changePIN:
            if await self.isValidPin() {
                oldAccessPin = inputPin // Store the old PIN
                isAccessPinChangeInProgress = true
                inputPin = AppValue.empty
                firstPin = AppValue.empty
                secondPin = AppValue.empty
                state = .create
                
                Router.shared.navigateTo(.userAccessPin(state: .create))
            } else {
                inputPin = AppValue.empty
                // Error description is already set in isValidPin()
            }

        case .forgetPin:
            // Show forget PIN confirmation popup
            showForgetPinPopup = true
        }
    }
    
    @MainActor
    func editAccessPin() async {
        defer { isLoading = false }
        isLoading = true
        
        guard let user = await interactor.getUserLocalData() else {
            isError = true
            description = "User not found"
            return
        }
        
        do {
            _ = try await interactor.editNewPIN(
                newAccessPin: newAccessPin,
                previousAccessPin: oldAccessPin
            )
            
            // Update local user data
            user.accessPin = newAccessPin
            await interactor.updateUserLocalData(user: user)
            
            // Show success and reset
            showAccessPinSuccessPopup = true
            resetPinChangeFlow()
            
        } catch {
            errorMessage = ErrorHandler.shared.handleError(error, context: .profile)
        }
    }
    
    @MainActor
    func createAccessPin() async {
        guard !firstPin.isEmpty, !secondPin.isEmpty else {
            isError = true
            return
        }
        
        guard Self.constantTimeEquals(firstPin, secondPin) else {
            description = AppTextAuthCompPin.invalidPinMatchText
            isError = true
            return
        }
        
        do {
            guard let user = await interactor.getUserLocalData() else {
                isError = true
                description = "User not found"
                return
            }
            
            _ = try await interactor.createAccessPin(accessPin: firstPin)
            
            // Update local user data
            user.accessPin = firstPin
            await interactor.updateUserLocalData(user: user)
        } catch {
            isError = true
            switch error {
            case let NetworkError.apiError(apiResponse, _):
                description = apiResponse.data.description
            case let NetworkError.networkError(message, _):
                description = message
            default:
                description = error.localizedDescription
            }
        }
    }
    
    var title: String {
        switch state {
        case .create:
            return isAccessPinChangeInProgress ? AppTextAuthCompPin.titleCreateChangePin : AppTextAuthCompPin.titleCreatePin
        case .revalidate:
            return isAccessPinChangeInProgress ? AppTextAuthCompPin.revalidateChangePinTitle : AppTextAuthCompPin.revalidatePinTitle
        case .authenticate:
            return AppTextAuthCompPin.titleAuthenticatePin
        case .changePIN:
            return AppTextAuthCompPin.titleChangePin
        case .forgetPin:
            return AppTextAuthCompPin.titleAuthenticatePin
        }
    }
    
    func setDescriptionPIN() {
        if !isError {
            switch state {
            case .create:
                if isAccessPinChangeInProgress {
                    descriptionPIN = AppTextAuthCompPin.createChangePinTitle
                } else {
                    descriptionPIN = AppTextAuthCompPin.createPinTitle
                }
            case .revalidate:
                if isAccessPinChangeInProgress {
                    descriptionPIN = AppTextAuthCompPin.revalidateChangePinTitle
                } else {
                    descriptionPIN = AppTextAuthCompPin.revalidatePinTitle
                }
            case .authenticate:
                descriptionPIN = AppTextAuthCompPin.titleAuthenticatePin
            case .changePIN:
                descriptionPIN = AppTextAuthCompPin.changePinTitle
            case .forgetPin:
                descriptionPIN = AppTextAuthCompPin.titleAuthenticatePin
            }
        }
    }
    
    private func revalidatePinMatched() -> Bool {
        let matched = Self.constantTimeEquals(firstPin, secondPin)
        if !matched {
            // Set error description when PINs don't match
            description = AppTextAuthCompPin.invalidPinMatchText
        }
        return matched
    }
    
    func resetPinChangeFlow() {
        isAccessPinChangeInProgress = false
        oldAccessPin = AppValue.empty
        newAccessPin = AppValue.empty
        firstPin = AppValue.empty
        secondPin = AppValue.empty
        inputPin = AppValue.empty
        isError = false
        description = AppValue.empty
    }
    
    @MainActor
    func handleForgetPin() async {
        // Hide the popup first
        showForgetPinPopup = false
        
        // Call backend API to delete access PIN
        do {
            _ = try await interactor.deleteAccessPin()
            Logger.info("Access PIN successfully deleted from backend", category: .authentication)
            
            // Update local user data to remove PIN
            if var localUser = await interactor.getUserLocalData() {
                localUser.accessPin = nil
                await interactor.updateUserLocalData(user: localUser)
            }
            
        } catch {
            Logger.error("Failed to delete access PIN from backend: \(error)", category: .authentication)
            isError = true
            errorMessage = ErrorHandler.shared.handleError(error, context: .login)
            return
        }

        clearLoginState()
        resetAuthenticationState()
        appStateManager?.setUnauthenticated()
        Router.shared.popToRoot()

        Logger.info("User successfully logged out via forget PIN", category: .authentication)
    }
    
    func cancelForgetPin() {
        showForgetPinPopup = false
    }
}

// MARK: - Biometric Authentication
extension AuthenticationPresenter {
    func checkFaceIDAvailability() {
        let context = LAContext()
        defer { context.invalidate() }
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isFaceIdAvailable = true
            isFaceIdEnabledFromUserDefaults = UserDefaults.standard.bool(forKey: UserDefaultType.isFaceIdEnabled.rawValue)
        } else {
            isFaceIdAvailable = false
            isFaceIdEnabledFromUserDefaults = false
        }
    }
    
    func isFaceIdEnabled(state: PinMode) -> Bool {
        return isFaceIdEnabledFromUserDefaults && state == .authenticate && isFaceIdAvailable
    }

    func hasStoredAccessPin() async -> Bool {
        return await interactor.getUserLocalData()?.accessPin != nil
    }

    @MainActor
    func authenticateWithFaceID() async {
        let context = LAContext()
        defer { context.invalidate() }
        var error: NSError?

        // Check if Face ID is available on the device
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Device does not support Face ID
            isError = true
            description = AppTextAuthProfile.descFaceIdNotSupported
            return
        }

        // Check if Face ID is enabled in app settings
        guard isFaceIdEnabledFromUserDefaults else {
            isError = true
            description = AppTextAuthProfile.descFaceIdNotEnabled
            return
        }

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: AppTextAuthBiometric.activationPrompt
                ) { success, authenticationError in
                    if success {
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: authenticationError ?? NSError(
                            domain: "AuthenticationError",
                            code: -1
                        ))
                    }
                }
            }
            isPinAuthorized = true
            // State transition handled by AccountCheckerView onChange
            Router.shared.popToRoot()
        } catch {
            isError = true
            description = AppTextAuthProfile.descFailedFaceID(error: error.localizedDescription)
        }
    }

    func updateFaceIdPreference(_ isEnabled: Bool) {
        isFaceIdEnabledFromUserDefaults = isEnabled
        UserDefaults.standard.set(isEnabled, forKey: UserDefaultType.isFaceIdEnabled.rawValue)
    }
    
    @MainActor
    func activateFaceIdFirstTime() async {
        await requestFaceIDActivation()
        isPinAuthorized = true
    }
    
    func skipFaceIdActivation() {
        isPinAuthorized = true
    }
    
    @MainActor
    func requestFaceIDActivation() async {
        let context = LAContext()
        defer { context.invalidate() }
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            isError = true
            description = AppTextAuthProfile.descFaceIdNotSupported
            return
        }

        do {
            try await withCheckedThrowingContinuation { continuation in
                context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: AppTextAuthBiometric.prompt
                ) { success, authenticationError in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: authenticationError ?? NSError(domain: "FaceID", code: -1))
                    }
                }
            }

            updateFaceIdPreference(true)
        } catch {
            isError = true
            description = AppTextAuthProfile.descFailedFaceID(error: error.localizedDescription)
            // Reset toggle ke `false` secara manual
            isFaceIdEnabledFromUserDefaults = false
        }
    }
}

// MARK: - User Management
extension AuthenticationPresenter {
    
    @MainActor
    func updateAccount(updateUser: User) async {
        defer { isLoading = false }
        isLoading = true
        
        do {
            let response = try await interactor.updateUserById(user: updateUser)

            user = response
            Router.shared.popToRoot()
        } catch {
            errorMessage = ErrorHandler.shared.handleError(error, context: .profile)
        }
    }
    
    @MainActor
    func refreshUserFromSwiftData() async {
        if let userData = await interactor.getUserLocalData() {
            user = userData
        }
    }
    
    private func clearLoginState() {
        UserDefaults.standard.removeObject(forKey: UserDefaultType.isUserLoggedIn.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultType.firstTimeLogin.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultType.userId.rawValue)
        KeychainHelper.removeAll()
    }
    
    func isUserLoggedIn() -> Bool {
        return UserDefaults.standard.bool(forKey: UserDefaultType.isUserLoggedIn.rawValue)
    }
    
    func isFirstTimeLoggedIn() -> Bool {
        return UserDefaults.standard.bool(forKey: UserDefaultType.firstTimeLogin.rawValue)
    }
}

// MARK: - State Management
extension AuthenticationPresenter {
    @MainActor
    func resetAuthenticationState() {
        // Reset authentication state
        isPinAuthorized = false
        
        // Clear user data
        user = User()
        
        // Clear PIN state
        firstPin = AppValue.empty
        secondPin = AppValue.empty
        inputPin = AppValue.empty
        oldAccessPin = AppValue.empty
        newAccessPin = AppValue.empty
        isAccessPinChangeInProgress = false
        showAccessPinSuccessPopup = false
        showForgetPinPopup = false
        
        // Clear login credentials and validation errors
        email = AppValue.empty
        password = AppValue.empty
        clearValidationErrors()
        
        // Reset UI state
        isError = false
        isLoading = false
        description = AppValue.empty
        state = .authenticate
        
        // Reset colors
        textColor = AppColors.slate900
        pinColor = AppColors.purple500
    }
    
    private func updateUIForErrorState() {
        if isError {
            // Surface the error message on the PIN screen, which reads `descriptionPIN`.
            if !description.isEmpty {
                descriptionPIN = description
            }
        } else {
            description = AppValue.empty
            setDescriptionPIN()
        }
        textColor = isError ? AppColors.red500 : AppColors.slate900
        pinColor = isError ? AppColors.red500 : AppColors.purple500
    }
}

// MARK: - Form Validation Extension
extension AuthenticationPresenter {
    /// Setup form validation logic
    private func setupFormValidation() {
        isFormValid = { [weak self] in
            guard let self = self else { return false }
            // Simple validation without using main actor isolated methods
            return !self.email.isEmpty && !self.password.isEmpty
        }
    // Optionally, you can add more validation setup for registration fields here if needed
    }
    
    /// Validate all login form fields at once
    func validateAllFields() -> Bool {
        return formValidation.validateLoginForm(email: email, password: password)
    }
    
    /// Clear all validation errors
    func clearValidationErrors() {
        let loginFields = ValidationFieldName.FormFields.login
        formValidation.clearErrors(for: loginFields)
        // Also clear registration field errors
        let registerFields: [ValidationFieldName] = [.registerFullName, .registerEmail, .registerHealthFacilityName]
        formValidation.clearErrors(for: registerFields)
    }
    
    /// Check if login form is both filled and has no validation errors
    func isLoginFormValidAndFilled() -> Bool {
        // Check if fields are filled
        guard !email.isEmpty && !password.isEmpty else { return false }
        guard password.count >= 8 else { return false }
        // Check if there are no validation errors for login fields
        let hasEmailError = formValidation.hasError(for: .loginEmail)
        let hasPasswordError = formValidation.hasError(for: .loginPassword)
        return !hasEmailError && !hasPasswordError
    }

    /// Check if registration form is both filled and has no validation errors
    func isRegisterFormValidAndFilled() -> Bool {
        // Check if fields are filled
        guard !registerFullName.isEmpty && !registerEmail.isEmpty && !registerHealthFacilityName.isEmpty else { return false }
        guard registerHealthFacilityType != nil else { return false }
        // Check if there are no validation errors for registration fields
        let hasFullNameError = formValidation.hasError(for: .registerFullName)
        let hasEmailError = formValidation.hasError(for: .registerEmail)
        let hasFacilityNameError = formValidation.hasError(for: .registerHealthFacilityName)
        return !hasFullNameError && !hasEmailError && !hasFacilityNameError
    }
    
    /// Clear all input fields and reset validation state
    func clearInput() {
        email = AppValue.empty
        password = AppValue.empty
        clearValidationErrors()
        isError = false
        description = AppValue.empty
        errorMessage = AppValue.empty
        registerEmail = AppValue.empty
        registerFullName = AppValue.empty
        registerHealthFacilityName = AppValue.empty
        registerHealthFacilityType = nil
        isChoosingRegistrationType = true
    }
}
