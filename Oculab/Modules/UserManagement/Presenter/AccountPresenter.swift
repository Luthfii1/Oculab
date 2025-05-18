//
//  AccountPresenter.swift
//  Oculab
//
//  Created by Risa on 11/05/25.
//

import Foundation
import SwiftUI

class AccountPresenter: ObservableObject {
    var interactor: AccountInteractor? = AccountInteractor()

    @Published var isUserLoading = false
    @Published var isRegistering = false
    @Published var showSuccessPopup = false
    @Published var successInfo: (name: String, role: String) = ("", "")
    @Published var registrationError: String? = nil
    
    @Published var groupedAccounts: [String: [AccountResponse]] = [:]
    @Published var sortedGroupedAccounts: [String] = []
    
    func isFormValid(name: String, email: String, role: String) -> Bool {
        let emailRegex = "^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$"
        let validEmail = email.range(of: emailRegex, options: .regularExpression) != nil
        
        return !name.isEmpty && validEmail && !role.isEmpty
    }
    
    func getRoleType(from roleString: String) -> RolesType {
        return RolesType(rawValue: roleString) ?? .LAB
    }
    
    func groupAccountsByName(accounts: [AccountResponse]) -> [String: [AccountResponse]] {
        var grouped: [String: [AccountResponse]] = [:]

        for account in accounts {
            guard let firstLetter = account.name.first?.uppercased() else { continue }
            grouped[firstLetter, default: []].append(account)
        }

        for key in grouped.keys {
            grouped[key]?.sort { $0.name < $1.name }
        }

        return grouped
    }

    @MainActor
    func fetchAllAccount() async {
        isUserLoading = true
        defer { isUserLoading = false }

        do {
            let response = try await interactor?.getAllAccount()

            if let response {
                groupedAccounts = groupAccountsByName(accounts: response)
                sortedGroupedAccounts = groupedAccounts.keys.sorted()
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
    func registerNewAccount(role: String, name: String, email: String) async {
        isRegistering = true
        
        do {
            // Convert string to enum
            let roleType = getRoleType(from: role)
            
            // Call the interactor to register the account
            let result = try await interactor?.registerAccount(
                roleType: roleType,
                name: name,
                email: email
            )
            
            // Handle success
            if let result = result {
                print("Registration successful: \(result.id), \(result.username)")
                
                successInfo = (name: name, role: roleType.rawValue)
                
                showSuccessPopup = true
                
                Task {
                    await fetchAllAccount()
                }
            } else {

                registrationError = "Failed to register account: No response from server"
            }
            
        } catch {
            print("Registration error: \(error)")
                
                switch error {
                case let NetworkError.apiError(apiResponse):
                    registrationError = apiResponse.data.description
                    
                case let NetworkError.networkError(message):
                    registrationError = message
                    
                default:
                    registrationError = error.localizedDescription
                }
        }
        isRegistering = false
    }
    
    func resetForm() {
        showSuccessPopup = false
    }

    func navigateTo(_ destination: Router.Route) {
        Router.shared.navigateTo(destination)
    }
    
    func navigateBack() {
        Router.shared.navigateBack()
    }
}
