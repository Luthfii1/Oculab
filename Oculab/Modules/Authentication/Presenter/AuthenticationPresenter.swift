//
//  AuthenticationPresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 06/11/24.
//

import Foundation
import SwiftUI

class AuthenticationPresenter: ObservableObject {
    var interactor: AuthenticationInteractor? = AuthenticationInteractor()

    @Published var isLoading: Bool = false {
        didSet {
            if isLoading {
                buttonText = "Loading..."
            } else {
                buttonText = "Login"
            }
        }
    }

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var buttonText: String = "Login"
    @Published var isKeyboardVisible: Bool = false

    func isFilled() -> Bool {
        return !email.isEmpty && !password.isEmpty && !isLoading
    }

    @MainActor
    func login() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let loginData = try await interactor?.login(email: email, password: password)
            if let data = loginData {
                print("Success login with id: \(data.userId)")
            }

            let accountData = try await interactor?.getAccountById()
            if let data = accountData {
                print("Success get account: \(data.role)")

                if data.accessPin != nil {
                    print("No access pin, redirect to setup screen")
                    Router.shared.navigateTo(.userAccessPin(
                        title: "Atur PIN",
                        description: "Atur PIN untuk kemudahan login di sesi berikutnya"
                    ))
                }
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
    func logoutAccount() {
        for userDefault in UserDefaultType.allCases {
            UserDefaults.standard.removeObject(forKey: userDefault.rawValue)
        }
    }
}
