//
//  ProfilePresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/11/24.
//

import Foundation

class ProfilePresenter: ObservableObject {
    private var interactor: ProfileInteractorProtocol
    private var authInteractor: AuthenticationInteractor

    @Published var user: User = .init()
    @Published var oldPassword: String = "" {
        didSet {
            validatePasswords()
            isOldPasswordError = false
        }
    }

    @Published var inputPassword: String = "" {
        didSet {
            validatePasswords()
        }
    }

    @Published var confirmPassword: String = "" {
        didSet {
            validatePasswords()
        }
    }

    @Published var buttonText: String = "Simpan Perubahan"
    @Published var isError: Bool = false
    @Published var isOldPasswordError: Bool = false {
        didSet {
            isOldPasswordError == true ? (descriptionOldPassword = "Password lama tidak cocok") :
                (descriptionOldPassword = "")
        }
    }

    @Published var descriptionPasswordConfirm: String =
        "Pastikan password konfirmasi cocok dengan password yang Anda masukkan sebelumnya"
    @Published var descriptionOldPassword: String = ""
    @Published var isLoading = false {
        didSet {
            buttonText = isLoading ? "Loading..." : "Simpan Perubahan"
        }
    }

    init(interactor: ProfileInteractorProtocol, authInteractor: AuthenticationInteractor) {
        self.interactor = interactor
        self.authInteractor = authInteractor
        Task {
            await self.getUser()
        }
    }

    private func validatePasswords() {
        print("desc: \(descriptionPasswordConfirm)")
        // Only show validation messages if user has started typing the confirmation
        guard !confirmPassword.isEmpty else {
            isError = false
            descriptionPasswordConfirm =
                "Pastikan password konfirmasi cocok dengan password yang Anda masukkan sebelumnya"
            return
        }

        // Check if passwords match
        if !confirmPassword.isEmpty && inputPassword != confirmPassword {
            isError = true
            descriptionPasswordConfirm = "Password konfirmasi tidak cocok"
        } else if !confirmPassword.isEmpty && inputPassword == confirmPassword {
            isError = false
            descriptionPasswordConfirm = "Password konfirmasi cocok"
        }
    }

    @MainActor
    func getUser() async {
        user = await authInteractor.getUserLocalData() ?? User()
    }

    @MainActor
    func logout() {
        for item in UserDefaultType.allCases {
            UserDefaults.standard.removeObject(forKey: item.rawValue)
        }
    }

    func isPasswordEditButtonEnabled() -> Bool {
        return !oldPassword.isEmpty &&
            !inputPassword.isEmpty &&
            !confirmPassword.isEmpty &&
            !isError && (inputPassword == confirmPassword)
    }

    func resetEditPassword() {
        oldPassword = ""
        inputPassword = ""
        confirmPassword = ""
        isError = false
        descriptionPasswordConfirm =
            "Pastikan password konfirmasi cocok dengan password yang Anda masukkan sebelumnya"
    }

    func navigateTo(_ destination: Router.Route) {
        Router.shared.navigateTo(destination)
    }

    @MainActor
    func postEditPassword(authPresenter: AuthenticationPresenter) async {
        guard let updateUser = await authInteractor.getUserLocalData() else {
            print("no data")
            return
        }

        updateUser.password = confirmPassword
        updateUser.previousPassword = oldPassword

        do {
            let response = try await authInteractor.updateUserById(user: updateUser)

            user = response
            Router.shared.popToRoot()
        } catch {
            isOldPasswordError = true
            switch error {
            case let NetworkError.apiError(apiResponse):
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")
                descriptionOldPassword = apiResponse.data.description

            case let NetworkError.networkError(message):
                print("Network error: \(message)")
                descriptionOldPassword = message

            default:
                print("Unknown error: \(error.localizedDescription)")
                descriptionOldPassword = error.localizedDescription
            }
        }
    }
}
