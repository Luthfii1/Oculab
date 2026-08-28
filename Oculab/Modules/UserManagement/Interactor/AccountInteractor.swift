//
//  AccountInteractor.swift
//  Oculab
//
//  Created by Risa on 11/05/25.
//

import Foundation

class AccountInteractor: ObservableObject {
    private let networkService: NetworkServiceProtocol
    private let apiGetAllAccount = API.BE + "/user/get-all-user-data"
    private let apiRegisterAccount = API.BE + "/user/register"
    private let apiDeleteAccount = API.BE + "/user/delete-user/"
    private let apiEditAccount = API.BE + "/user/update-user/"
    private var authInteractor: AuthenticationInteractor
    private var authPresenter: AuthenticationPresenter?
    
    init(
        authInteractor: AuthenticationInteractor,
        authPresenter: AuthenticationPresenter? = nil,
        networkService: NetworkServiceProtocol = DependencyInjection.shared.networkService
    ) {
        self.authInteractor = authInteractor
        self.authPresenter = authPresenter
        self.networkService = networkService
    }
    
    func getAllAccount() async throws -> [Account] {
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw NSError(
                domain: "UserIdNotFound",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "User ID not found"]
            )
        }

        guard let token = KeychainHelper.string(for: .accessToken) else {
            throw URLError(.userAuthenticationRequired)
        }

        let headers = [
            "Authorization": "Bearer \(token)"
        ]

        let response: APIResponse<[Account]> = try await networkService.get(
            urlString: apiGetAllAccount + "/\(userId)",
            headers: headers
        )

        let result = response.data.map { account in
            Account(
                id: account.id,
                name: account.name,
                role: account.role,
                email: account.email,
                username: account.username ?? "",
                accessPin: account.accessPin ?? ""
            )
        }

        return result
    }
    
    func registerAccount(roleType: RolesType, name: String, email: String) async throws -> RegisterAccountResponse {
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw NSError(
                domain: "UserIdNotFound",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "User ID not found"]
            )
        }
        
        guard let token = KeychainHelper.string(for: .accessToken) else {
            throw URLError(.userAuthenticationRequired)
        }

        let headers = [
            "Authorization": "Bearer \(token)"
        ]
        
        let response: APIResponse<RegisterAccountResponse> = try await networkService.post(
            urlString: apiRegisterAccount + "/\(userId)",
            headers: headers,
            body: RegisterAccountBody(role: roleType, name: name, email: email)
        )
        
        return RegisterAccountResponse(
            id: response.data.id,
            email: response.data.email,
            inviteEmailed: response.data.inviteEmailed,
            passwordEmailed: response.data.passwordEmailed
        )
    }
    
    func editAccount(userId: String, name: String? = nil, role: RolesType? = nil) async throws -> EditAccountResponse {
        guard let token = KeychainHelper.string(for: .accessToken) else {
            throw URLError(.userAuthenticationRequired)
        }
        
        let requestBody = EditAccountBody(
            name: name,
            role: role
        )
        
        let headers = [
            "Authorization": "Bearer \(token)"
        ]
        
        let response: APIResponse<EditAccountResponse> = try await networkService.update(
            urlString: apiEditAccount + userId.lowercased(),
            headers: headers,
            body: requestBody
        )
        
        // Update SwiftData with edited user info
        let updatedUser = User(
            id: response.data.id,
            name: response.data.name,
            role: response.data.role,
            email: response.data.email,
            accessPin: "" // Keep existing or use empty  
        )
        await authInteractor.updateUserLocalData(user: updatedUser)
        
        // Refresh AuthenticationPresenter if the edited user is the currently logged in user
        if let currentUserId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue),
           currentUserId == userId {
            await authPresenter?.refreshUserFromSwiftData()
        }
        
        return EditAccountResponse(
            id: response.data.id,
            name: response.data.name,
            role: response.data.role,
            email: response.data.email
        )
    }
    
    func deleteAccount(userId: String) async throws -> DeleteAccountResponse {
        guard let token = KeychainHelper.string(for: .accessToken) else {
            throw URLError(.userAuthenticationRequired)
        }

        let headers = [
            "Authorization": "Bearer \(token)"
        ]
        
        let response: APIResponse<DeleteAccountResponse> = try await networkService.delete(
            urlString: apiDeleteAccount + userId.lowercased(),
            headers: headers,
            body: EmptyBody()
        )
        
        return DeleteAccountResponse(
            id: response.data.id,
            name: response.data.name,
            role: response.data.role,
            email: response.data.email
        )
    }
}
