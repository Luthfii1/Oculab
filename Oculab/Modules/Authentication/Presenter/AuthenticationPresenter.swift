//
//  AuthenticationPresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 06/11/24.
//

import Foundation
import SwiftUI

class AuthenticationPresenter: ObservableObject {
    static let shared = AuthenticationPresenter()
    private var interactor: AuthenticationInteractor?
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

    init(interactor: AuthenticationInteractor? = AuthenticationInteractor()) {
        self.interactor = interactor
    }

    func setPassword() {
        UserDefaults.standard.set(secondPin, forKey: UserDefaultType.accessPin.rawValue)
    }

    func isValidPin() -> Bool {
        UserDefaults.standard.string(forKey: UserDefaultType.accessPin.rawValue) == inputPin
    }

    func confirmedPin() -> Bool {
        firstPin == secondPin
    }

    var isFilled: Bool {
        !email.isEmpty && !password.isEmpty && !isLoading
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
            if let data = accountData, data.accessPin == nil {
                Router.shared.navigateTo(.userAccessPin(state: .create))
            }
        } catch let error as NetworkError {
            handleNetworkError(error)
        } catch {
            print("Unknown error: \(error.localizedDescription)")
        }
    }

    @MainActor
    func logoutAccount() {
        for item in UserDefaultType.allCases {
            UserDefaults.standard.removeObject(forKey: item.rawValue)
        }
    }

    private func handleNetworkError(_ error: NetworkError) {
        switch error {
        case let .apiError(apiResponse):
            print("Error type: \(apiResponse.data.errorType)")
            print("Error description: \(apiResponse.data.description)")
        case let .networkError(message):
            print("Network error: \(message)")
        }
    }
}
