//
//  AccountPresenter.swift
//  Oculab
//
//  Created by Risa on 11/05/25.
//

import Foundation
import SwiftUI

class AccountPresenter: ObservableObject {
    private var interactor: AccountInteractor
    private var searchTimer: Timer?
    private var debounceTime: TimeInterval = 0.3
    
    // MARK: - Form Validation
    var formValidation: FormValidationViewModel
    
    // MARK: - UI State
    @Published var isUserLoading = false
    @Published var isRegistering = false
    @Published var isEditing = false
    @Published var isDeleting = false
    @Published var isSearching: Bool = false
    
    // MARK: - Form Fields with Validation
    @Published var name = AppValue.empty {
        didSet {
            validateNameField()
        }
    }
    @Published var role: String = AppValue.empty {
        didSet {
            validateRoleField()
        }
    }
    @Published var userId: String = AppValue.empty
    @Published var email: String = AppValue.empty {
        didSet {
            validateEmailField()
        }
    }
    
    // MARK: - Validation Error States
    @Published var nameError: String = AppValue.empty
    @Published var emailError: String = AppValue.empty
    @Published var roleError: String = AppValue.empty
    @Published var isError = false
    @Published var editError: String? = nil
    @Published var registrationError: String? = nil
    @Published var deletionError: String? = nil
    
    // MARK: - Success States
    @Published var registrationSuccess: (name: String, role: String) = (AppValue.empty, AppValue.empty)
    @Published var editSuccess: (name: String, role: String) = (AppValue.empty, AppValue.empty)
    @Published var deletionSuccess: (userName: String, message: String)? = nil
    
    // MARK: - Alert States
    @Published var showSuccessPopup = false
    @Published var showDeleteSuccessAlert = false
    @Published var showDeleteConfirmationPopup = false
    
    // MARK: - Search and Data
    @Published var searchText: String = AppValue.empty {
        didSet {
            searchTimer?.invalidate()
            searchTimer = Timer.scheduledTimer(withTimeInterval: debounceTime, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.searchAccounts(query: self?.searchText ?? AppValue.empty)
                }
            }
        }
    }
    @Published var filteredGroupedAccounts: [String: [Account]] = [:]
    @Published var filteredSortedGroupedAccounts: [String] = []
    @Published var groupedAccounts: [String: [Account]] = [:]
    @Published var sortedGroupedAccounts: [String] = []
    
    // MARK: - User Selection
    @Published var selectedUser: SelectedUser? = nil
    @Published var userToDelete: SelectedUser? = nil
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        return validateUserForm() && !isRegistering && !isEditing
    }
    
    var displayedGroupedAccounts: [String: [Account]] {
        return searchText.isEmpty ? groupedAccounts : filteredGroupedAccounts
    }
    
    var displayedSortedGroupedAccounts: [String] {
        return searchText.isEmpty ? sortedGroupedAccounts : filteredSortedGroupedAccounts
    }
    
    init(interactor: AccountInteractor) {
        self.interactor = interactor
        self.formValidation = FormValidationViewModel()
    }
    
    deinit {
        searchTimer?.invalidate()
    }
}

// MARK: - Models
extension AccountPresenter {
    struct SelectedUser: Identifiable {
        var id: String
        var name: String
    }
}

// MARK: - Form Validation
extension AccountPresenter {
    func validateUserForm() -> Bool {
        return formValidation.validateUserForm(
            name: name,
            email: email,
            role: role
        )
    }
    
    private func validateNameField() {
        if !name.isEmpty {
            let isValid = ValidationManager.shared.validateName(name, fieldName: ValidationFieldName.userName.rawValue)
            nameError = isValid ? AppValue.empty : (ValidationManager.shared.getError(for: ValidationFieldName.userName.rawValue) ?? AppValue.empty)
        } else {
            nameError = AppValue.empty
            ValidationManager.shared.clearError(for: ValidationFieldName.userName.rawValue)
        }
    }
    
    private func validateEmailField() {
        if !email.isEmpty {
            let isValid = ValidationManager.shared.validateEmail(email, fieldName: ValidationFieldName.userEmail.rawValue)
            emailError = isValid ? AppValue.empty : (ValidationManager.shared.getError(for: ValidationFieldName.userEmail.rawValue) ?? AppValue.empty)
            
            // Update legacy error state for backward compatibility
            if !isValid {
                isError = true
                editError = emailError
            } else {
                editError = nil
                isError = false
            }
        } else {
            emailError = AppValue.empty
            editError = nil
            isError = false
            ValidationManager.shared.clearError(for: ValidationFieldName.userEmail.rawValue)
        }
    }
    
    private func validateRoleField() {
        if !role.isEmpty {
            let isValid = ValidationManager.shared.validateRequired(role, fieldName: ValidationFieldName.userRole.rawValue)
            roleError = isValid ? AppValue.empty : (ValidationManager.shared.getError(for: ValidationFieldName.userRole.rawValue) ?? AppValue.empty)
        } else {
            roleError = AppValue.empty
            ValidationManager.shared.clearError(for: ValidationFieldName.userRole.rawValue)
        }
    }
    
    // Legacy validation methods for backward compatibility
    func validateEmail(_ email: String) -> Bool {
        return ValidationManager.shared.validateEmail(email, fieldName: ValidationFieldName.legacyEmail.rawValue)
    }
    
    func validateName(_ name: String) -> Bool {
        return ValidationManager.shared.validateName(name, fieldName: ValidationFieldName.legacyName.rawValue)
    }
    
    func validateRole(_ role: String) -> Bool {
        return ValidationManager.shared.validateRequired(role, fieldName: ValidationFieldName.legacyRole.rawValue)
    }
    
    func isFormValid(name: String, email: String, role: String) -> Bool {
        return formValidation.validateUserForm(name: name, email: email, role: role)
    }
}

// MARK: - Account Data Management
extension AccountPresenter {
    @MainActor
    func registerNewAccountWithValidation(role: String, name: String, email: String) async {
        guard validateUserForm() else {
            print("🔘 User form validation failed")
            return
        }
        
        formValidation.clearAllErrors()
        await registerNewAccount(role: role, name: name, email: email)
    }
    
    @MainActor
    func editSelectedUserWithValidation(role: String, name: String, userId: String) async {
        guard validateUserForm() else {
            print("🔘 User form validation failed")
            return
        }
        
        formValidation.clearAllErrors()
        await editSelectedUser(role: role, name: name, userId: userId)
    }
    
    @MainActor
    func fetchAllAccount() async {
        isUserLoading = true
        defer { isUserLoading = false }

        do {
            let response = try await interactor.getAllAccount()

            groupedAccounts = groupAccountsByName(accounts: response)
            sortedGroupedAccounts = groupedAccounts.keys.sorted()
            
            // If there was an active search, apply it to the new data
            if !searchText.isEmpty {
                searchAccounts(query: searchText)
            }

        } catch {
            _ = ErrorHandler.shared.handleError(error)
        }
    }
    
    @MainActor
    func registerNewAccount(role: String, name: String, email: String) async {
        isRegistering = true
        defer { isRegistering = false }
        
        do {
            let roleType = getRoleType(from: role)
            
            _ = try await interactor.registerAccount(
                roleType: roleType,
                name: name,
                email: email
            )
            
            // Registration successful - result is non-nil
            registrationSuccess = (name: name, role: roleType.rawValue)
            showSuccessPopup = true
            
            Task {
                await fetchAllAccount()
            }
            
            clearForm()
            
        } catch {
            registrationError = ErrorHandler.shared.handleError(error)
        }
    }
    
    @MainActor
    func editSelectedUser(role: String, name: String, userId: String) async {
        isEditing = true
        defer { isEditing = false }
        
        do {
            let result = try await interactor.editAccount(
                userId: userId,
                name: name,
                role: getRoleType(from: role)
            )
            
            selectedUser = SelectedUser(id: result.id, name: result.name)
            editSuccess = (name: name, role: role)
            showSuccessPopup = true
            
            Task {
                await fetchAllAccount()
            }
            
        } catch {
            editError = ErrorHandler.shared.handleError(error)
        }
    }
    
    @MainActor
    func confirmDeleteSelectedUser() async {
        showDeleteConfirmationPopup = false
        
        guard let userToDelete = userToDelete else { return }
        
        isDeleting = true
        defer { isDeleting = false }
        
        do {
            let result = try await interactor.deleteAccount(userId: userToDelete.id)

            deletionSuccess = (userName: result.name, message: AppTextUserMgmtView.successDeleteAccount(result.name))
            clearSelection()
            
            await fetchAllAccount()
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            showDeleteSuccessAlert = true
            
        } catch {
            deletionError = ErrorHandler.shared.handleError(error)
        }
        
        self.userToDelete = nil
    }
    
    private func groupAccountsByName(accounts: [Account]) -> [String: [Account]] {
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
}

// MARK: - Search and Filter Operations
extension AccountPresenter {
    @MainActor
    func searchAccounts(query: String) {
        if query.isEmpty {
            filteredGroupedAccounts = [:]
            filteredSortedGroupedAccounts = []
            return
        }
        
        isSearching = true
        defer { isSearching = false }
        
        var newFilteredGroups: [String: [Account]] = [:]
        
        for (_, accounts) in groupedAccounts {
            for account in accounts {
                if account.name.lowercased().contains(query.lowercased()) ||
                   account.email.lowercased().contains(query.lowercased()) {
                    
                    guard let firstLetter = account.name.first?.uppercased() else { continue }
                    
                    if newFilteredGroups[firstLetter] != nil {
                        newFilteredGroups[firstLetter]?.append(account)
                    } else {
                        newFilteredGroups[firstLetter] = [account]
                    }
                }
            }
        }
        
        for key in newFilteredGroups.keys {
            newFilteredGroups[key]?.sort { $0.name < $1.name }
        }
        
        filteredGroupedAccounts = newFilteredGroups
        filteredSortedGroupedAccounts = newFilteredGroups.keys.sorted()
    }
    
    func clearSearch() {
        searchText = AppValue.empty
        filteredGroupedAccounts = [:]
        filteredSortedGroupedAccounts = []
    }
    
    @MainActor
    func performSearch() {
        searchAccounts(query: searchText)
    }
}

// MARK: - User Selection Management
extension AccountPresenter {
    func selectUser(_ account: Account) {
        selectedUser = SelectedUser(id: account.id, name: account.name)
    }
    
    func clearSelection() {
        selectedUser = nil
    }
    
    func setAccount(account: Account) {
        self.name = account.name
        self.role = account.role.rawValue
        self.userId = account.id
    }
    
    func findAccountById(_ id: String) -> Account? {
        for (_, accounts) in groupedAccounts {
            if let account = accounts.first(where: { $0.id == id }) {
                return account
            }
        }
        return nil
    }
    
    func isCurrentUser(_ userId: String) -> Bool {
        guard let currentUserId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            return false
        }
        return currentUserId == userId
    }
}

// MARK: - Dialog and Alert Management
extension AccountPresenter {
    func showDeleteConfirmation() {
        guard let selectedUser = selectedUser else { return }
        
        // Check if user is trying to delete themselves
        if let currentUserId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue),
           currentUserId == selectedUser.id {
            return
        }
        
        userToDelete = selectedUser
        showDeleteConfirmationPopup = true
    }
    
    func dismissDeleteConfirmation() {
        showDeleteConfirmationPopup = false
        userToDelete = nil
    }
    
    func dismissDeleteAlert() {
        showDeleteSuccessAlert = false
        deletionSuccess = nil
    }
    
    func resetForm() {
        clearForm()
        clearErrors()
        showSuccessPopup = false
    }
    
    private func clearForm() {
        self.name = AppValue.empty
        self.role = AppValue.empty
        self.email = AppValue.empty
        self.userId = AppValue.empty
    }
    
    private func clearErrors() {
        nameError = AppValue.empty
        emailError = AppValue.empty
        roleError = AppValue.empty
        isError = false
        editError = nil
        registrationError = nil
        deletionError = nil
        formValidation.clearAllErrors()
    }
}

// MARK: - Navigation
extension AccountPresenter {
    func navigateTo(_ destination: Router.Route) {
        Router.shared.navigateTo(destination)
    }
    
    func navigateBack() {
        Router.shared.navigateBack()
    }
}

// MARK: - Helper Methods
extension AccountPresenter {
    func getRoleType(from roleString: String) -> RolesType {
        return RolesType(rawValue: roleString) ?? .LAB
    }
}

