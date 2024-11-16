//
//  AuthenticationPresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 06/11/24.
//

import Foundation
import SwiftUI

enum PinMode {
    case create, revalidate, authenticate
}

class AuthenticationPresenter: ObservableObject {
    private var interactor: AuthenticationInteractor
    @Published var isLoading = false {
        didSet { buttonText = isLoading ? "Loading..." : "Login" }
    }

    @Published var email = ""
    @Published var password = ""
    @Published var buttonText = "Login"
    @Published var isKeyboardVisible = false
    @Published var inputPin = ""
    @Published var firstPin = ""
    @Published var secondPin = ""
    @Published var isOpeningApp = false
    @Published var user: User = .init()
    @Published var state: PinMode = .authenticate
    @Published var isPinAuthorized: Bool = false

    init(interactor: AuthenticationInteractor) {
        self.interactor = interactor
    }

    func setPassword() {
        UserDefaults.standard.set(secondPin, forKey: UserDefaultType.accessPin.rawValue)
    }

    func isValidPin() async -> Bool {
        print("accessPin: \(await interactor.getUserLocalData()?.accessPin ?? "empty")")
        return await interactor.getUserLocalData()?.accessPin == inputPin
    }

    func confirmedPin() -> Bool {
        if firstPin == secondPin {
            Task {
                self.user.accessPin = self.secondPin
                await self.updateAccount()
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
        }
    }

    var description: String {
        switch state {
        case .create: return "Atur PIN untuk kemudahan login di sesi berikutnya"
        case .revalidate: return "Masukkan PIN kembali untuk konfirmasi"
        case .authenticate: return "Masukkan PIN untuk mengakses aplikasi"
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
                print("PINs do not match. Try again.")
                inputPin = ""
            }
        case .authenticate:
            Task {
                if await self.isValidPin() {
                    isPinAuthorized = true
                    print("Authentication successful")
                    Router.shared.popToRoot()
                } else {
                    print("Invalid PIN. Try again.")
                    self.inputPin = ""
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
    func logoutAccount() {
        for item in UserDefaultType.allCases {
            UserDefaults.standard.removeObject(forKey: item.rawValue)
        }
    }

    @MainActor
    func updateAccount() async {
        do {
            print("name updated: \(String(describing: user.name))")
//            guard let userUpdate = user else { return print("No data of user") }
            let response = try await interactor.updateUserById(user: user)

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
}
