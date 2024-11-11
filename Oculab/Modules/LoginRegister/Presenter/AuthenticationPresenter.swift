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

    func isFilled() -> Bool {
        return !email.isEmpty && !password.isEmpty && !isLoading
    }

    func login() {
        isLoading = true

        interactor?.login(email: email, password: password, completion: { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(data):
                    print(data)
                case let .failure(error):
                    print("Error description: \(error.description)")
                    print("Error type: \(error.errorType)")
                }

                self.isLoading = false
            }
        })
    }
}
