//
//  AccountInteractor.swift
//  Oculab
//
//  Created by Risa on 11/05/25.
//

import Foundation

struct AccountResponse: Codable, Identifiable {
    var id: String
    var name: String
    var role: String
    var email: String
    var username: String?
}

class AccountInteractor: ObservableObject {
    private let apiGetAllAccount = API.BE + "/user/get-all-user-data"

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
                username: account.username ?? ""
            )
        }

        return result
    }
}
