//
//  AccountInteractor.swift
//  Oculab
//
//  Created by Risa on 11/05/25.
//

import Foundation

class AccountInteractor: ObservableObject {
    private let apiGetAllAccount = API.BE + "/user/get-all-user-data"
    private let apiRegisterAccount = API.BE + "/user/register"
    private let apiUpdatePasswordAccount = API.BE + "/user/update-password/"
    private let apiDeleteAccount = API.BE + "/user/delete-user/"
    
    func getAllAccount() async throws -> [AccountResponse] {
        guard let token = UserDefaults.standard.string(forKey: UserDefaultType.accessToken.rawValue) else {
            throw URLError(.userAuthenticationRequired)
        }
        print("TOKEN", token)

        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]

        let response: APIResponse<[Account]> = try await NetworkHelper.shared.get(
            urlString: apiGetAllAccount,
            headers: headers
        )

        let result = response.data.map { account in
            AccountResponse(
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
    
    func registerAccount(
        roleType: RolesType,
        name: String,
        email: String
    ) async throws -> RegisterAccountResponse {
        let response: APIResponse<RegisterAccountResponse> = try await NetworkHelper.shared.post(
            urlString: apiRegisterAccount,
            body: RegisterAccountBody(role: roleType, name: name, email: email)
        )
        
        //username & currentPassword will be sent to user's email
        print("Successfully registered \(name) as \(roleType.rawValue)")
        return RegisterAccountResponse(
            id: response.data.id,
            username: response.data.username,
            currentPassword: response.data.currentPassword
        )
    }
    
    func updatePassword(
        userId: String,
        previousPassword: String,
        newPassword: String
    ) async throws -> UpdatePasswordResponse {
        let response: APIResponse<UpdatePasswordResponse> = try await NetworkHelper.shared.update(
            urlString: apiUpdatePasswordAccount + userId.lowercased(),
            body: UpdatePasswordBody(previousPassword: previousPassword, newPassword: newPassword)
        )
        
        return UpdatePasswordResponse(
            userId: response.data.userId,
            username: response.data.username,
            currentPassword: response.data.currentPassword
        )
    }
    
    func deleteAccount(
        userId: String
    ) async throws -> AccountResponse {
        let response: APIResponse<Account> = try await NetworkHelper.shared.delete(
            urlString: apiDeleteAccount + userId.lowercased(),
            body: EmptyBody()
        )
        
        return AccountResponse(
            id: response.data.id,
            name: response.data.name,
            role: response.data.role,
            email: response.data.email,
            username: response.data.username ?? "",
            accessPin: response.data.accessPin ?? ""
        )
    }
}
