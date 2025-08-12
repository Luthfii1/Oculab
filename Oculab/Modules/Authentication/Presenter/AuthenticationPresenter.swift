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
    @Published var isSplashScreenVisible = true
    @Published var description: String = AppValue.empty
    @Published var textColor: Color = AppColors.slate900
    @Published var pinColor: Color = AppColors.purple500
    @Published var email = AppValue.empty
    @Published var password = AppValue.empty
    @Published var isKeyboardVisible = false
    @Published var firstPin = AppValue.empty
    @Published var secondPin = AppValue.empty
    @Published var isOpeningApp = false
    @Published var user: User = .init()
    @Published var isPinAuthorized: Bool = false
    @Published var descriptionPIN: String = AppValue.empty
    @Published var isFaceIdAvailable: Bool = false
    @Published var isFaceIdEnabledFromUserDefaults: Bool = UserDefaults.standard.bool(forKey: UserDefaultType.isFaceIdEnabled.rawValue)
    @Published var inputPin = AppValue.empty {
        didSet {
            if !inputPin.isEmpty {
                isError = false
            }
        }
    }
    let numbers = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["!", "0", "delete.left.fill"]
    ]

    @Published var isLoading = false

    @Published var isError: Bool = false {
        didSet {
            if !isError {
                description = AppValue.empty
            }
            textColor = isError ? AppColors.red500 : AppColors.slate900
            pinColor = isError ? AppColors.red500 : AppColors.purple500
        }
    }

    @Published var state: PinMode = .authenticate {
        didSet {
            setDescriptionPIN()
        }
    }

    @Published var oldAccessPin = AppValue.empty
    @Published var newAccessPin = AppValue.empty
    @Published var isAccessPinChangeInProgress = false
    @Published var showAccessPinSuccessPopup = false

    var isFilled: Bool {
        !email.isEmpty && !password.isEmpty && !isLoading
    }
    
    var loginButtonText: String {
        return isLoading ? AppState.loading : AppTextAuthLogin.buttonText
    }

    private var interactor: AuthenticationInteractor

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
        guard pin.count == 4 else { return }

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
                    Router.shared.popToRoot()
                }
            } else {
                isError = true
                inputPin = AppValue.empty
                // Error description is already set in revalidatePinMatched()
            }

        case .authenticate:
            Task {
                if await self.isValidPin() {
                    isPinAuthorized = true
                    Router.shared.popToRoot()
                } else {
                    inputPin = AppValue.empty
                    // Error description is already set in isValidPin()
                }
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
        isError = false
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
            let getAccountResponse = try await interactor.getAccountById()
            user = getAccountResponse

            // Reset the pin input state
            inputPin = AppValue.empty
            firstPin = AppValue.empty
            secondPin = AppValue.empty

            if getAccountResponse.accessPin == nil {
                // User needs to create PIN
                state = .create
                isPinAuthorized = false
            } else {
                // User needs to authenticate with existing PIN
                state = .authenticate
                isPinAuthorized = false
            }
        } catch {
            // Handle error and ensure user goes back to login
            isPinAuthorized = false
            clearLoginState()
            
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
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await interactor.login(email: email, password: password)
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
                    errorData: ApiErrorData(errorType: "UNKNOW_ERROR", description: error.localizedDescription)
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
        do {
            if let userData = await interactor.getUserLocalData() {
                user = userData
            }
        } catch {
            print("Error refreshing user from SwiftData: \(error.localizedDescription)")
        }
    }
}
