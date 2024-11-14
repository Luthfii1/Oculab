//
//  AuthenticationInteractor.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 06/11/24.
//

import Foundation

struct UserBody: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let userId: String
}

class AuthenticationInteractor: ObservableObject {
    private let apiAuthenticationService = API.BE + "/user"

    func login(email: String, password: String) async throws -> LoginResponse {
        let response: APIResponse<LoginResponse> = try await NetworkHelper.shared.post(
            urlString: apiAuthenticationService + "/login",
            body: UserBody(email: email, password: password)
        )

        // Store user data
        UserDefaults.standard.set(response.data.accessToken, forKey: UserDefaultType.accessToken.rawValue)
        UserDefaults.standard.set(response.data.refreshToken, forKey: UserDefaultType.refreshToken.rawValue)
        UserDefaults.standard.set(true, forKey: UserDefaultType.isUserLoggedIn.rawValue)
        UserDefaults.standard.set(response.data.userId, forKey: UserDefaultType.userId.rawValue)

        return response.data
    }

    func getAccountById() async throws -> User {
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw NSError(
                domain: "UserIdNotFound",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "User ID not found"]
            )
        }

        let response: APIResponse<User> = try await NetworkHelper.shared.get(
            urlString: apiAuthenticationService + "/get-user-data-by-id/\(userId)"
        )
        return response.data
    }
}
