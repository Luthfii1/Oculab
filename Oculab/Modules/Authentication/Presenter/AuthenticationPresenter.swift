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
    @Published var description: String = ""
    @Published var textColor: Color = AppColors.slate900
    @Published var pinColor: Color = AppColors.purple500
    @Published var email = ""
    @Published var password = ""
    @Published var isKeyboardVisible = false
    @Published var firstPin = ""
    @Published var secondPin = ""
    @Published var isOpeningApp = false
    @Published var user: User = .init()
    @Published var isPinAuthorized: Bool = false
    @Published var descriptionPIN: String = ""
    @Published var isFaceIdAvailable: Bool = false
    @Published var isFaceIdEnabledFromUserDefaults: Bool = UserDefaults.standard.bool(forKey: UserDefaultType.isFaceIdEnabled.rawValue)
    @Published var inputPin = "" {
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
                description = ""
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
    
    @Published var oldAccessPin = ""
    @Published var newAccessPin = ""
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
                description = "PIN saat ini salah"
                return false
            }
        } else {
            // Normal authentication - check against stored PIN
            if await interactor.getUserLocalData()?.accessPin != inputPin {
                isError = true
                description = "PIN salah, silakan coba lagi"
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
            inputPin = ""
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
                inputPin = ""
                // Error description is already set in revalidatePinMatched()
            }

        case .authenticate:
            Task {
                if await self.isValidPin() {
                    isPinAuthorized = true
                    Router.shared.popToRoot()
                } else {
                    inputPin = ""
                    // Error description is already set in isValidPin()
                }
            }

        case .changePIN:
            Task {
                if await self.isValidPin() {
                    oldAccessPin = inputPin // Store the old PIN
                    isAccessPinChangeInProgress = true
                    inputPin = ""
                    firstPin = ""
                    secondPin = ""
                    state = .create
                    
                    Router.shared.navigateTo(.userAccessPin(state: .create))
                } else {
                    inputPin = ""
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
        oldAccessPin = ""
        newAccessPin = ""
        firstPin = ""
        secondPin = ""
        inputPin = ""
        isAccessPinChangeInProgress = false
        isError = false
        description = ""
    }
    
    func setDescriptionPIN() {
        if !isError {
            switch state {
            case .create:
                if isAccessPinChangeInProgress {
                    descriptionPIN = "Masukkan PIN baru Anda"
                } else {
                    descriptionPIN = "Atur PIN untuk kemudahan login di sesi berikutnya"
                }
            case .revalidate:
                if isAccessPinChangeInProgress {
                    descriptionPIN = "Konfirmasi PIN baru Anda"
                } else {
                    descriptionPIN = "Masukkan PIN kembali untuk konfirmasi"
                }
            case .authenticate:
                descriptionPIN = "Masukkan PIN untuk mengakses aplikasi"
            case .changePIN:
                descriptionPIN = "Masukkan PIN Anda saat ini"
            }
        }
    }
        
    var title: String {
        switch state {
        case .create:
            return isAccessPinChangeInProgress ? "PIN Baru" : "Atur PIN"
        case .revalidate:
            return isAccessPinChangeInProgress ? "Konfirmasi PIN Baru" : "Konfirmasi PIN"
        case .authenticate:
            return "Masukkan PIN"
        case .changePIN:
            return "PIN Saat Ini"
        }
    }

    func clearInput() {
        email = ""
        password = ""
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
            description = "PIN tidak cocok, silakan coba lagi"
        }
        return matched
    }
    
    // MARK: USER AUTHENTICATION

    @MainActor
    func getAccountById() async {
        do {
            let getAccountResponse = try await interactor.getAccountById()
            user = getAccountResponse

            // Reset the pin input state before navigation
            inputPin = ""
            firstPin = ""
            secondPin = ""

            if getAccountResponse.accessPin == nil {
                state = .create
                Router.shared.navigateTo(.userAccessPin(state: .create))
            } else {
                state = .authenticate
                Router.shared.navigateTo(.userAccessPin(state: .authenticate))
            }
        } catch {
            // Handle error
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

    @MainActor
    func login() async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await interactor.login(email: email, password: password)
            handleErrorState(isError: false)
        } catch {
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
        }
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
            description = "Perangkat Anda tidak mendukung Face ID"
            return
        }

        // Check if Face ID is enabled in app settings
        guard isFaceIdEnabledFromUserDefaults else {
            isError = true
            description = "Face ID belum diaktifkan. Silakan aktifkan di Pengaturan Profil"
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
                self.description = "Autentikasi Face ID gagal: \(error.localizedDescription)"
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
            description = "Perangkat Anda tidak mendukung Face ID"
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
            description = "Gagal mengaktifkan Face ID: \(error.localizedDescription)"
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
