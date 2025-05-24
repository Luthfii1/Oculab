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
    private var searchTimer: Timer?

    @Published var isUserLoading = false
    
    @Published var name = ""
    @Published var role: String = ""
    @Published var userId: String = ""
    @Published var email: String = "" {
        didSet {
            if !validateEmail(email) {
                isError = true
                editError = "Format email tidak valid"
            } else {
                editError = nil
                isError = false
            }
        }
    }
    
    @Published var isRegistering = false
    @Published var registrationError: String? = nil
    @Published var registrationSuccess: (name: String, role: String) = ("", "")
    @Published var showSuccessPopup = false
    
    @Published var isDeleting = false
    @Published var deletionError: String? = nil
    @Published var deletionSuccess: (userName: String, message: String)? = nil
    
    @Published var isEditing = false
    @Published var editError: String? = nil
    @Published var isError = false
    @Published var editSuccess: (name: String, role: String) = ("", "")
    private var debounceTime: TimeInterval = 0.3

    @Published var searchText: String = "" {
        didSet {
            // Cancel any existing timer
            searchTimer?.invalidate()
            
            // Create a new timer
            searchTimer = Timer.scheduledTimer(withTimeInterval: debounceTime, repeats: false) { [weak self] _ in
                self?.searchAccounts(query: self?.searchText ?? "")
            }
        }
    }
    @Published var isSearching: Bool = false
    @Published var filteredGroupedAccounts: [String: [Account]] = [:]
    @Published var filteredSortedGroupedAccounts: [String] = []
    
    @Published var groupedAccounts: [String: [Account]] = [:]
    @Published var sortedGroupedAccounts: [String] = []
    
    @Published var selectedUser: SelectedUser? = nil
    
    // Model for selected user
    struct SelectedUser: Identifiable {
        var id: String
        var name: String
    }
    
    // Computed property to get accounts based on search state
    var displayedGroupedAccounts: [String: [Account]] {
        return searchText.isEmpty ? groupedAccounts : filteredGroupedAccounts
    }
    
    var displayedSortedGroupedAccounts: [String] {
        return searchText.isEmpty ? sortedGroupedAccounts : filteredSortedGroupedAccounts
    }
    
    deinit {
        searchTimer?.invalidate()
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
                
                // If there was an active search, apply it to the new data
                if !searchText.isEmpty {
                    searchAccounts(query: searchText)
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
    
    // Search functionality
    func searchAccounts(query: String) {
        if query.isEmpty {
            // Reset filtered results when query is empty
            filteredGroupedAccounts = [:]
            filteredSortedGroupedAccounts = []
            return
        }
        
        // Set searching state
        isSearching = true
        
        // Filter accounts based on the query
        var newFilteredGroups: [String: [Account]] = [:]
        
        // Iterate through all accounts in all groups
        for (_, accounts) in groupedAccounts {
            for account in accounts {
                // Check if the account name or email contains the query (case insensitive)
                if account.name.lowercased().contains(query.lowercased()) ||
                   account.email.lowercased().contains(query.lowercased()) {
                    
                    // Get the first letter to use as the group key
                    guard let firstLetter = account.name.first?.uppercased() else { continue }
                    
                    // Add to filtered results
                    if newFilteredGroups[firstLetter] != nil {
                        newFilteredGroups[firstLetter]?.append(account)
                    } else {
                        newFilteredGroups[firstLetter] = [account]
                    }
                }
            }
        }
        
        // Sort accounts within each group by name
        for key in newFilteredGroups.keys {
            newFilteredGroups[key]?.sort { $0.name < $1.name }
        }
        
        // Update filtered results
        filteredGroupedAccounts = newFilteredGroups
        filteredSortedGroupedAccounts = newFilteredGroups.keys.sorted()
        
        isSearching = false
    }
    
    func clearSearch() {
        searchText = ""
        filteredGroupedAccounts = [:]
        filteredSortedGroupedAccounts = []
    }
    
    func performSearch() {
        searchAccounts(query: searchText)
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
                registrationSuccess = (name: name, role: roleType.rawValue)
                showSuccessPopup = true
                
                Task {
                    await fetchAllAccount()
                }
            } else {
                registrationError = "Failed to register account: No response from server"
            }
            
            self.name = ""
            self.role = ""
            self.email = ""
            
        } catch {
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
    
    func getRoleType(from roleString: String) -> RolesType {
        return RolesType(rawValue: roleString) ?? .LAB
    }
    
    func resetForm() {
        showSuccessPopup = false
    }
    
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$"
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    func validateName(_ name: String) -> Bool {
        return !name.isEmpty
    }
    
    func validateRole(_ role: String) -> Bool {
        return !role.isEmpty
    }
    
    func isFormValid(name: String, email: String, role: String) -> Bool {
        return validateName(name) && validateEmail(email) && validateRole(role)
    }
    
    func findAccountById(_ id: String) -> Account? {
        for (_, accounts) in groupedAccounts {
            if let account = accounts.first(where: { $0.id == id }) {
                return account
            }
        }
        
        return nil
    }
    
    @MainActor
    func editSelectedUser(role: String, name: String, userId: String) async {
        
        isEditing = true
        defer { isEditing = false }
        
        do {
            let result = try await interactor?.editAccount(
                userId: userId,
                name: name,
                role: getRoleType(from: role)
            )
            
            if let result = result {
                selectedUser = SelectedUser(id: result.id, name: result.name)
                editSuccess = (name: name, role: role)
                showSuccessPopup = true
                
                Task {
                    await fetchAllAccount()
                }
            } else {
                editError = "Failed to edit account: No response from server"
            }
            
        } catch {
            switch error {
            case let NetworkError.apiError(apiResponse):
                editError = apiResponse.data.description
                
            case let NetworkError.networkError(message):
                editError = message
                
            default:
                editError = error.localizedDescription
            }
        }
    }
    
    @MainActor
    func deleteSelectedUser() async {
        guard let userId = selectedUser?.id else { return }
        
        isDeleting = true
        defer { isDeleting = false }
        
        do {
            let result = try await interactor?.deleteAccount(userId: userId)
            
            if let result = result {
                deletionSuccess = (userName: result.name, message: "\(result.name) has been successfully deleted.")
                clearSelection()
                
                Task {
                    await fetchAllAccount()
                }
            } else {
                deletionError = "Failed to delete account: No response from server"
            }
            
        } catch {
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
    
    func setAccount(account: Account) {
        self.name = account.name
        self.role = account.role.rawValue
        self.userId = account.id
    }
}

