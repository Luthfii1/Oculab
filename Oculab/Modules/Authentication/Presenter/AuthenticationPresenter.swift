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
    @Published var description: String = ""
    @Published var textColor: Color = AppColors.slate900
    @Published var pinColor: Color = AppColors.purple500
    @Published var email = ""
    @Published var password = ""
    @Published var buttonText = "Login"
    @Published var isKeyboardVisible = false
    @Published var firstPin = ""
    @Published var secondPin = ""
    @Published var isOpeningApp = false
    @Published var user: User = .init()
    @Published var isPinAuthorized: Bool = false
    @Published var descriptionPIN: String = ""
    @Published var isFaceIdAvailable: Bool = false
    @Published var isFaceIdEnabled: Bool = false
    @Published var inputPin = "" {
        didSet {
            if !inputPin.isEmpty {
                isError = false
            }
        }
    }

    @Published var isLoading = false {
        didSet { buttonText = isLoading ? "Loading..." : "Login" }
    }

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

    var isFilled: Bool {
        !email.isEmpty && !password.isEmpty && !isLoading
    }

    var title: String {
        switch state {
        case .create: return "Atur PIN"
        case .revalidate: return "Konfirmasi PIN"
        case .authenticate: return "Masukkan PIN"
        case .changePIN: return "PIN Saat Ini"
        }
    }

    private var interactor: AuthenticationInteractor

    init(interactor: AuthenticationInteractor) {
        self.interactor = interactor
        setDescriptionPIN()
    }

    @MainActor
    func isValidPin() async -> Bool {
        if await interactor.getUserLocalData()?.accessPin != inputPin {
            isError = true
            return false
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
                user.accessPin = secondPin
                await updateAccount(updateUser: user)
                isPinAuthorized = true
            } else {
                isError = true
                inputPin = ""
            }

        case .authenticate:
            Task {
                if await self.isValidPin() {
                    isPinAuthorized = true
                    Router.shared.popToRoot()
                } else {
                    inputPin = ""
                }
            }

        case .changePIN:
            Task {
                if await self.isValidPin() {
                    inputPin = ""
                    state = .create
                    Router.shared.navigateTo(.userAccessPin(state: .create))
                } else {
                    inputPin = ""
                }
            }
        }
    }

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

    func setDescriptionPIN() {
        if !isError {
            switch state {
            case .create:
                descriptionPIN = "Atur PIN untuk kemudahan login di sesi berikutnya"
            case .revalidate:
                descriptionPIN = "Masukkan PIN kembali untuk konfirmasi"
            case .authenticate:
                descriptionPIN = "Masukkan PIN untuk mengakses aplikasi"
            case .changePIN:
                descriptionPIN = "Masukkan PIN Anda saat ini"
            }
        }
    }

    private func revalidatePinMatched() -> Bool {
        return firstPin == secondPin
    }

    // MARK: FACE ID AUTHORIZATION

    func checkFaceIDAvailability() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isFaceIdAvailable = true
            isFaceIdEnabled = UserDefaults.standard.bool(forKey: UserDefaultType.isFaceIdEnabled.rawValue)
        } else {
            isFaceIdAvailable = false
            isFaceIdEnabled = false
        }
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
        guard isFaceIdEnabled else {
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
        isFaceIdEnabled = isEnabled
        UserDefaults.standard.set(isEnabled, forKey: "isFaceIdEnabled")
    }
}
