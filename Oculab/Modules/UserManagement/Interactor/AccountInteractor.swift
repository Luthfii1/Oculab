//
//  AccountInteractor.swift
//  Oculab
//
//  Created by Risa on 11/05/25.
//

import Foundation

class AccountInteractor: ObservableObject {
    private let apiGetAllAccount = API.BE + "/user/get-all-user-data"
    private let apiRegisterAccount = API.BE_PROD + "/user/register"
    private let apiDeleteAccount = API.BE + "/user/delete-user/"
    private let apiEditAccount = API.BE_STAGING + "/user/update-user/"
    
    func getAllAccount() async throws -> [Account] {
        guard let token = UserDefaults.standard.string(forKey: UserDefaultType.accessToken.rawValue) else {
            throw URLError(.userAuthenticationRequired)
        }
        print("TOKEN", token)

        let headers = [
            "Authorization": "Bearer \(token)"
        ]

        let response: APIResponse<[Account]> = try await NetworkHelper.shared.get(
            urlString: apiGetAllAccount,
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
        let response: APIResponse<RegisterAccountResponse> = try await NetworkHelper.shared.post(
            urlString: apiRegisterAccount,
            body: RegisterAccountBody(role: roleType, name: name, email: email)
        )
        
        //username & currentPassword will be sent to user's email
        return RegisterAccountResponse(
            id: response.data.id,
            username: response.data.username,
            currentPassword: response.data.currentPassword
        )
    }
    
    func editAccount(userId: String, name: String? = nil, role: RolesType? = nil) async throws -> EditAccountResponse {
        print("masuk editaccount interactor")
        guard let token = UserDefaults.standard.string(forKey: UserDefaultType.accessToken.rawValue) else {
            throw URLError(.userAuthenticationRequired)
        }
        print("masuk editaccount interactor")
        
        print("TOKEN", token)
        
        let requestBody = EditAccountBody(
            name: name,
            role: role
        )
        
        let headers = [
            "Authorization": "Bearer \(token)"
        ]
        
        let response: APIResponse<EditAccountResponse> = try await NetworkHelper.shared.update(
            urlString: apiEditAccount + userId.lowercased(),
            body: requestBody,
            headers: headers
        )
        
        print("Successfully edited account: \(response.data.id)")
        
        return EditAccountResponse(
            id: response.data.id,
            name: response.data.name,
            role: response.data.role,
            email: response.data.email
        )
    }
    
    func deleteAccount(userId: String) async throws -> DeleteAccountResponse {
        guard let token = UserDefaults.standard.string(forKey: UserDefaultType.accessToken.rawValue) else {
            throw URLError(.userAuthenticationRequired)
        }
        
        print("TOKEN", token)

        let headers = [
            "Authorization": "Bearer \(token)"
        ]
        
        let response: APIResponse<DeleteAccountResponse> = try await NetworkHelper.shared.delete(
            urlString: apiDeleteAccount + userId.lowercased(),
            body: EmptyBody(),
            headers: headers
        )
        
        return DeleteAccountResponse(
            id: response.data.id,
            name: response.data.name,
            role: response.data.role,
            email: response.data.email
        )
    }
}
