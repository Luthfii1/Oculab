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

    func login(
        email: String,
        password: String,
        completion: @escaping (Result<LoginResponse, ApiErrorData>) -> Void
    ) {
        NetworkHelper.shared.post(
            urlString: apiAuthenticationService + "/login",
            body: UserBody(email: email, password: password)
        ) { (result: Result<APIResponse<LoginResponse>, APIResponse<ApiErrorData>>) in
            DispatchQueue.main.async {
                switch result {
                case let .success(response):
                    completion(.success(response.data))

                case let .failure(error):
                    completion(.failure(error.data))
                }
            }
        }
    }
}
