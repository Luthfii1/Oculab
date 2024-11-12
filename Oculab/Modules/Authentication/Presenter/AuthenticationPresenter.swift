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
            }

        } catch {
            // Handle error
            switch error {
            case let NetworkError.apiError(apiResponse):
//                        errorMessage = apiResponse.data.description
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")

            case let NetworkError.networkError(message):
//                        errorMessage = message
                print("Network error: \(message)")

            default:
//                        errorMessage = error.localizedDescription
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
