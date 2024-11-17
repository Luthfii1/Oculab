//
//  AuthenticationPresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 06/11/24.
//

import Foundation
import SwiftUI

enum PinMode {
    case create, revalidate, authenticate, changePIN
}

class AuthenticationPresenter: ObservableObject {
    private var interactor: AuthenticationInteractor
    @Published var isLoading = false {
        didSet { buttonText = isLoading ? "Loading..." : "Login" }
    }

    @Published var isError: Bool = false {
        didSet {
            print("isError changed to: \(isError)")
            if !isError {
                description = ""
            }
            textColor = isError ? AppColors.red500 : AppColors.slate900
            pinColor = isError ? AppColors.red500 : AppColors.purple500
        }
    }

    @Published var description: String = ""

    @Published var textColor: Color = AppColors.slate900
    @Published var pinColor: Color = AppColors.purple500
    @Published var email = ""
    @Published var password = ""
    @Published var buttonText = "Login"
    @Published var isKeyboardVisible = false
    @Published var inputPin = "" {
        didSet {
            if !inputPin.isEmpty {
                isError = false
            }
        }
    }

    @Published var firstPin = ""
    @Published var secondPin = ""
    @Published var isOpeningApp = false
    @Published var user: User = .init()
    @Published var state: PinMode = .authenticate {
        didSet {
            setDescriptionPIN()
        }
    }

    @Published var isPinAuthorized: Bool = false
    @Published var descriptionPIN: String = ""

    init(interactor: AuthenticationInteractor) {
        self.interactor = interactor
        setDescriptionPIN()
    }

    func setPassword() {
        UserDefaults.standard.set(secondPin, forKey: UserDefaultType.accessPin.rawValue)
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

    func confirmedPin() -> Bool {
        if firstPin == secondPin {
            Task {
                self.user.accessPin = self.secondPin
                await self.updateAccount(updateUser: self.user)
            }
        }
        return firstPin == secondPin
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

    @MainActor
    func handlePinInput(_ pin: String) {
        guard pin.count == 4 else { return }

        switch state {
        case .create:
            firstPin = pin
            inputPin = ""
            state = .revalidate
            Router.shared.navigateTo(.userAccessPin(state: .revalidate))

        case .revalidate:
            secondPin = pin
            if confirmedPin() {
                setPassword()
                isPinAuthorized = true
                print("PIN set successfully")
            } else {
                isError = true
                inputPin = ""
            }

        case .authenticate:
            Task {
                if await self.isValidPin() {
                    isPinAuthorized = true
                    print("Authentication successful")
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

            print("accessPin: \(getAccountResponse.accessPin ?? "nil")")
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
                handleErrorState(isError: true, errorDescription: apiResponse.data.description)
            case let NetworkError.networkError(message):
                handleErrorState(isError: true, errorDescription: "Network error: \(message)")
            default:
                handleErrorState(isError: true, errorDescription: "Unknown error: \(error.localizedDescription)")
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

    private func handleErrorState(isError: Bool, errorDescription: String? = nil) {
        DispatchQueue.main.async {
            if isError, let errorDescription = errorDescription {
                self.description = errorDescription
            }
            self.isError = isError
        }
    }
}
