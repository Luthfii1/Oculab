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
    @Published var oldPassword: String = AppValue.empty {
        didSet {
            validatePasswords()
            isOldPasswordError = false
        }
    }

    @Published var inputPassword: String = AppValue.empty {
        didSet {
            validatePasswords()
        }
    }

    @Published var confirmPassword: String = AppValue.empty {
        didSet {
            validatePasswords()
        }
    }

    @Published var isError: Bool = false
    @Published var isOldPasswordError: Bool = false {
        didSet {
            isOldPasswordError == true ? (descriptionOldPassword = AppTextAuthProfile.oldPasswordNotMatched) :
                (descriptionOldPassword = AppValue.empty)
        }
    }

    @Published var descriptionPasswordConfirm: String = AppTextAuthProfile.descConfirmPassword
    @Published var descriptionOldPassword: String = AppValue.empty
    @Published var isLoading = false

    var saveChangesButtonText: String {
        return isLoading ? AppState.loading : AppAction.saveChanges
    }

    @Published var showSuccessPopup: Bool = false
    
    init(interactor: ProfileInteractorProtocol, authInteractor: AuthenticationInteractor) {
        self.interactor = interactor
        self.authInteractor = authInteractor
        Task {
            await self.getUser()
        }
    }

    private func validatePasswords() {
        // Only show validation messages if user has started typing the confirmation
        guard !confirmPassword.isEmpty else {
            isError = false
            descriptionPasswordConfirm =
                AppTextAuthProfile.descConfirmPassword
            return
        }

        // Check if passwords match
        if !confirmPassword.isEmpty && inputPassword != confirmPassword {
            isError = true
            descriptionPasswordConfirm = AppTextAuthProfile.confirmPasswordError
        } else if !confirmPassword.isEmpty && inputPassword == confirmPassword {
            isError = false
            descriptionPasswordConfirm = AppTextAuthProfile.confirmPasswordSuccess
        }
    }

    @MainActor
    func getUser() async {
        user = await authInteractor.getUserLocalData() ?? User()
    }

    @MainActor
    func logout() async {
        // Clear all UserDefaults except onboarding status
        for item in UserDefaultType.allCases where item != .hasSeenOnboarding {
            UserDefaults.standard.removeObject(forKey: item.rawValue)
        }
        
        // The AccountCheckerView will observe the isUserLoggedIn change
        // and automatically trigger state reset and navigation
    }

    func isPasswordEditButtonEnabled() -> Bool {
        return !oldPassword.isEmpty &&
            !inputPassword.isEmpty &&
            !confirmPassword.isEmpty &&
            !isError && (inputPassword == confirmPassword)
    }

    func resetEditPassword() {
        oldPassword = AppValue.empty
        inputPassword = AppValue.empty
        confirmPassword = AppValue.empty
        isError = false
        descriptionPasswordConfirm = AppTextAuthProfile.descConfirmPassword
    }

    func navigateTo(_ destination: Router.Route) {
        Router.shared.navigateTo(destination)
    }

    @MainActor
    func postEditPassword(authPresenter: AuthenticationPresenter) async {
        guard !confirmPassword.isEmpty, !oldPassword.isEmpty else {
            descriptionOldPassword = AppTextAuthProfile.emptyPasswordError
            isOldPasswordError = true
            return
        }
        
        do {
            _ = try await interactor.editNewPassword(
                newPassword: confirmPassword,
                previousPassword: oldPassword)
            
            showSuccessPopup = true
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
    
    func backToProfilePage() {
        Router.shared.popToRoot()
    }
}
