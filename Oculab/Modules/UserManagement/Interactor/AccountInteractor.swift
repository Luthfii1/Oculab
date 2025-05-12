//
//  AccountInteractor.swift
//  Oculab
//
//  Created by Risa on 11/05/25.
//

import Foundation

class AccountInteractor: ObservableObject {
    private let apiGetAllAccount = API.BE_PROD + "/user/get-all-user-data"
    
    func getAllAccount() async throws -> [Account] {
        guard let token = UserDefaults.standard.string(forKey: UserDefaultType.accessToken.rawValue) else {
            throw URLError(.userAuthenticationRequired)
        }
        print(token)

        let headers = [
                "Authorization": "Bearer \(token)"
            ]

        let response: APIResponse<[Account]> = try await NetworkHelper.shared.get(
            urlString: apiGetAllAccount,
            headers: headers
        )
        print("Authorization: Bearer \(token)")
        return response.data
    }
}
