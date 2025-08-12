//
//  AuthenticationPresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 06/11/24.
//

import Foundation
import LocalAuthentication
import SwiftUI

enum PinMode {
    case create, revalidate, authenticate, changePIN
}

class AuthenticationPresenter: ObservableObject {
    // MARK: - UI State Properties
    @Published var isSplashScreenVisible = true
    @Published var description: String = AppValue.empty
    @Published var textColor: Color = AppColors.slate900
    @Published var pinColor: Color = AppColors.purple500
    @Published var isLoading = false
    @Published var isKeyboardVisible = false
    @Published var isOpeningApp = false
    
    // MARK: - Authentication State
    @Published var user: User = .init()
    @Published var isPinAuthorized: Bool = false
    @Published var email = AppValue.empty {
        didSet {
            updateValidationErrors()
        }
    }
    @Published var password = AppValue.empty {
        didSet {
            updateValidationErrors()
        }
    }
    @Published var emailError: String = AppValue.empty
    @Published var passwordError: String = AppValue.empty
    
    // MARK: - PIN Management State
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
    @Published var descriptionPIN: String = AppValue.empty
    @Published var state: PinMode = .authenticate {
        didSet {
            setDescriptionPIN()
        }
    }
    
    // MARK: - Biometric Authentication
    @Published var isFaceIdAvailable: Bool = false
    @Published var isFaceIdEnabledFromUserDefaults: Bool = UserDefaults.standard.bool(forKey: UserDefaultType.isFaceIdEnabled.rawValue)
    
    // MARK: - Error Handling
    @Published var isError: Bool = false {
        didSet {
            updateUIForErrorState()
        }
    }
    
    // MARK: - Constants
    let numbers = AppConstants.pinNumbers

    // MARK: - Dependencies
    private var interactor: AuthenticationInteractor
    weak var appStateManager: AppStateManager?

    // MARK: - Computed Properties
    var isFilled: Bool {
        let isEmailValid = ValidationHelpers.isValidEmail(email)
        let isPasswordValid = ValidationHelpers.isValidPassword(password)
        let isFormValid = isEmailValid && isPasswordValid && !isLoading
        
        return isFormValid
    }
    
    var loginButtonText: String {
        isLoading ? AppState.loading : AppTextAuthLogin.buttonText
    }

    // MARK: - Initialization
    init(interactor: AuthenticationInteractor) {
        self.interactor = interactor
        setDescriptionPIN()
    }
    
    // MARK: ACCESS PIN
    
    @MainActor
    func isValidPin() async -> Bool {
        // For PIN change flow, we should check against oldAccessPin, not the stored PIN
        if isAccessPinChangeInProgress {
            if oldAccessPin != inputPin {
                isError = true
                description = AppTextAuthCompPin.invalidPinText
                return false
            }
        } else {
            // Normal authentication - check against stored PIN
            if await interactor.getUserLocalData()?.accessPin != inputPin {
                isError = true
                description = AppTextAuthCompPin.invalidPinText
                return false
            }
        }
        
        isError = false
        return true
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
                    await postEditAccessPin()
                } else {
                    // This is initial PIN setup - just update locally and authorize
                    user.accessPin = secondPin
                    await createAccessPin()
                    await interactor.updateUserLocalData(user: user)
                    isPinAuthorized = true
                    // State transition handled by AccountCheckerView onChange
                }
            } else {
                isError = true
                inputPin = AppValue.empty
                // Error description is already set in revalidatePinMatched()
            }

        case .authenticate:
            if await self.isValidPin() {
                isPinAuthorized = true
                // State transition handled by AccountCheckerView onChange
            } else {
                inputPin = AppValue.empty
                // Error description is already set in isValidPin()
            }

        case .changePIN:
            Task {
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
            }
        }
    }
    
    @MainActor
    func postEditAccessPin() async {
        guard !newAccessPin.isEmpty, !oldAccessPin.isEmpty else {
            print("PIN fields are empty")
            isError = true
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
            isError = true
            switch error {
            case let NetworkError.apiError(apiResponse):
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")
                description = apiResponse.data.description

            case let NetworkError.networkError(message):
                print("Network error: \(message)")
                description = message

            default:
                print("Unknown error: \(error.localizedDescription)")
                description = error.localizedDescription
            }
        }
    }
    
    @MainActor
    func createAccessPin() async {
        guard !firstPin.isEmpty, !secondPin.isEmpty else {
            isError = true
            return
        }
        
        if firstPin != secondPin {
            isError = true
        }
        
        do {
            _ = try await interactor.createAccessPin(accessPin: secondPin)
            
            // Show success and reset
            showAccessPinSuccessPopup = true
            resetPinChangeFlow()
        } catch {
            isError = true
            switch error {
            case let NetworkError.apiError(apiResponse):
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")
                description = apiResponse.data.description

            case let NetworkError.networkError(message):
                print("Network error: \(message)")
                description = message

            default:
                print("Unknown error: \(error.localizedDescription)")
                description = error.localizedDescription
            }
        }
    }
    
    func resetPinChangeFlow() {
        oldAccessPin = AppValue.empty
        newAccessPin = AppValue.empty
        firstPin = AppValue.empty
        secondPin = AppValue.empty
        inputPin = AppValue.empty
        isAccessPinChangeInProgress = false
        isError = false
        description = AppValue.empty
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
        }
    }

    func clearInput() {
        email = AppValue.empty
        password = AppValue.empty
        emailError = AppValue.empty
        passwordError = AppValue.empty
        isError = false
    }
    
    private func updateValidationErrors() {
        // Only show errors if user has started typing
        if !email.isEmpty && !ValidationHelpers.isValidEmail(email) {
            emailError = ValidationHelpers.ErrorMessage.invalidEmail
        } else {
            emailError = AppValue.empty
        }
        
        if !password.isEmpty && !ValidationHelpers.isValidPassword(password) {
            passwordError = ValidationHelpers.ErrorMessage.invalidPassword
        } else {
            passwordError = AppValue.empty
        }
    }

    private func handleErrorState(isError: Bool, errorData: ApiErrorData? = nil) {
        DispatchQueue.main.async {
            if isError, let errorData = errorData {
                print("Error type: \(errorData.errorType)")
                print("Error description: \(errorData.description)")
                self.description = errorData.description
            }
            self.isError = isError
        }
    }
    
    private func revalidatePinMatched() -> Bool {
        let matched = firstPin == secondPin
        if !matched {
            // Set error description when PINs don't match
            description = AppTextAuthCompPin.invalidPinMatchText
        }
        return matched
    }
    
    // MARK: USER AUTHENTICATION

    func isUserLoggedIn() -> Bool {
        return UserDefaults.standard.bool(forKey: UserDefaultType.isUserLoggedIn.rawValue)
    }

    @MainActor
    func getAccountById() async {
        do {
            // Add timeout handling
            let getAccountResponse = try await withTimeout(seconds: 30) { [self] in
                try await self.interactor.getAccountById()
            }
            user = getAccountResponse

            // Reset the pin input state
            inputPin = AppValue.empty
            firstPin = AppValue.empty
            secondPin = AppValue.empty

            if getAccountResponse.accessPin == nil {
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
            // Handle error and ensure user goes back to login
            isPinAuthorized = false
            clearLoginState()
            appStateManager?.setUnauthenticated()
            
            switch error {
            case let NetworkError.apiError(apiResponse):
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")
                handleErrorState(isError: true, errorData: apiResponse.data)

            case let NetworkError.networkError(message):
                print("Network error: \(message)")
                handleErrorState(
                    isError: true,
                    errorData: ApiErrorData(errorType: "NETWORK_ERROR", description: message)
                )

            default:
                print("Unknown error: \(error.localizedDescription)")
                handleErrorState(
                    isError: true,
                    errorData: ApiErrorData(errorType: "AUTHENTICATION_ERROR", description: error.localizedDescription)
                )
            }
        }
    }

    @MainActor
    func login() async -> Bool {
        // Clear previous errors
        isError = false
        emailError = AppValue.empty
        passwordError = AppValue.empty
        
        // Validate before attempting login
        guard ValidationHelpers.isValidEmail(email) else {
            emailError = ValidationHelpers.ErrorMessage.invalidEmail
            return false
        }
        
        guard ValidationHelpers.isValidPassword(password) else {
            passwordError = ValidationHelpers.ErrorMessage.invalidPassword
            return false
        }
        
        isLoading = true
        defer { 
            isLoading = false 
        }

        do {
            let response = try await interactor.login(email: email, password: password)
            
            handleErrorState(isError: false)
            return true
        } catch {
            // Clear any partial login state on failure
            clearLoginState()
            
            switch error {
            case let NetworkError.apiError(apiResponse):
                handleErrorState(isError: true, errorData: apiResponse.data)
            case let NetworkError.networkError(message):
                handleErrorState(
                    isError: true,
                    errorData: ApiErrorData(errorType: "NETWORK_ERROR", description: message)
                )
            default:
                handleErrorState(
                    isError: true,
                    errorData: ApiErrorData(errorType: "UNKNOWN_ERROR", description: error.localizedDescription)
                )
            }
            return false
        }
    }

    private func clearLoginState() {
        UserDefaults.standard.removeObject(forKey: UserDefaultType.isUserLoggedIn.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultType.userId.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultType.accessToken.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultType.refreshToken.rawValue)
    }

    @MainActor
    func updateAccount(updateUser: User) async {
        do {
            let response = try await interactor.updateUserById(user: updateUser)

            user = response
            Router.shared.popToRoot()
        } catch {
            switch error {
            case let NetworkError.apiError(apiResponse):
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")

            case let NetworkError.networkError(message):
                print("Network error: \(message)")

            default:
                print("Unknown error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: FACE ID AUTHORIZATION

    func checkFaceIDAvailability() {
        let context = LAContext()
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

    @MainActor
    func authenticateWithFaceID() async {
        let context = LAContext()
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
            try await withCheckedThrowingContinuation { continuation in
                context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: "Autentikasi untuk mengakses aplikasi"
                ) { success, authenticationError in
                    if success {
                        continuation.resume(returning: ())
                        DispatchQueue.main.async {
                            self.isPinAuthorized = true
                            // State transition handled by AccountCheckerView onChange
                            Router.shared.popToRoot()
                        }
                    } else {
                        continuation.resume(throwing: authenticationError ?? NSError(
                            domain: "AuthenticationError",
                            code: -1
                        ))
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isError = true
                self.description = AppTextAuthProfile.descFailedFaceID(error: error.localizedDescription)
            }
        }
    }

    func updateFaceIdPreference(_ isEnabled: Bool) {
        isFaceIdEnabledFromUserDefaults = isEnabled
        UserDefaults.standard.set(isEnabled, forKey: "isFaceIdEnabled")
    }
    
    @MainActor
    func requestFaceIDActivation() async {
        let context = LAContext()
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
                    localizedReason: "Aktifkan Face ID untuk keamanan aplikasi"
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
    
    // MARK: - SwiftData Refresh
    @MainActor
    func refreshUserFromSwiftData() async {
        if let userData = await interactor.getUserLocalData() {
            user = userData
        }
    }
    
    // MARK: - State Reset
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
        
        // Clear login credentials and validation errors
        email = AppValue.empty
        password = AppValue.empty
        emailError = AppValue.empty
        passwordError = AppValue.empty
        
        // Reset UI state
        isError = false
        isLoading = false
        description = AppValue.empty
        state = .authenticate
        
        // Reset colors
        textColor = AppColors.slate900
        pinColor = AppColors.purple500
    }
}

// MARK: - Helper Methods
private extension AuthenticationPresenter {
    func updateUIForErrorState() {
        if !isError {
            description = AppValue.empty
        }
        textColor = isError ? AppColors.red500 : AppColors.slate900
        pinColor = isError ? AppColors.red500 : AppColors.purple500
    }
    
    func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw NSError(domain: "TimeoutError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Operation timed out"])
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}
