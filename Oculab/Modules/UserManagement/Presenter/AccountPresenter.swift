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

    // UI State
    @Published var isUserLoading = false
    @Published var isRegistering = false
    @Published var isDeleting = false
    @Published var showSuccessPopup = false
    
    @Published var registrationError: String? = nil
    @Published var registrationSuccess: (name: String, role: String) = ("", "")
    @Published var deletionError: String? = nil
    @Published var deletionSuccess: (userName: String, message: String)? = nil

    
    // Data
    @Published var groupedAccounts: [String: [Account]] = [:]
    @Published var sortedGroupedAccounts: [String] = []
    
    // Selected user for bottom sheet
    @Published var selectedUser: SelectedUser? = nil
    
    // Model for selected user
    struct SelectedUser: Identifiable {
        var id: String
        var name: String
    }
    
    // User selection methods
    func selectUser(_ account: Account) {
        selectedUser = SelectedUser(id: account.id, name: account.name)
    }
    
    func clearSelection() {
        selectedUser = nil
    }
    
    func groupAccountsByName(accounts: [Account]) -> [String: [Account]] {
        var grouped: [String: [Account]] = [:]

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
            let roleType = getRoleType(from: role)
            
            let result = try await interactor?.registerAccount(
                roleType: roleType,
                name: name,
                email: email
            )
            
            if let result = result {
                print("Registration successful: \(result.id), \(result.username)")
                
                registrationSuccess = (name: name, role: roleType.rawValue)
                
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
    
    func isFormValid(name: String, email: String, role: String) -> Bool {
        let emailRegex = "^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$"
        let validEmail = email.range(of: emailRegex, options: .regularExpression) != nil
        
        return !name.isEmpty && validEmail && !role.isEmpty
    }
    
    func getRoleType(from roleString: String) -> RolesType {
        return RolesType(rawValue: roleString) ?? .LAB
    }
    
    func resetForm() {
        showSuccessPopup = false
    }
    
    @MainActor
    func deleteSelectedUser() async {
        guard let userId = selectedUser?.id else { return }
        
        isDeleting = true
        defer { isDeleting = false }
        
        do {
            let result = try await interactor?.deleteAccount(userId: userId)
            
            if let result = result {
                print("Deletion successful: \(result.id): \(result.name)")
                deletionSuccess = (userName: result.name, message: "\(result.name) has been successfully deleted.")

                clearSelection()
                
                Task {
                    await fetchAllAccount()
                }
            } else {
                deletionError = "Failed to delete account: No response from server"
            }
            
        } catch {
            print("Deletion error: \(error)")
                
            switch error {
            case let NetworkError.apiError(apiResponse):
                deletionError = apiResponse.data.description
                
            case let NetworkError.networkError(message):
                deletionError = message
                
            default:
                deletionError = error.localizedDescription
            }
        }
    }

    func navigateTo(_ destination: Router.Route) {
        Router.shared.navigateTo(destination)
    }
    
    func navigateBack() {
        Router.shared.navigateBack()
    }
}
