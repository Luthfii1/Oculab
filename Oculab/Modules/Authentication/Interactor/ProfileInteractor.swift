//
//  ProfileInteractor.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/11/24.
//

import Foundation

protocol ProfileInteractorProtocol {
    func editNewPassword(password: String) async throws -> User
    func editNewPIN(pin: String) async throws
    func activateFaceID() async throws
}

class ProfileInteractor: ProfileInteractorProtocol {
    private let apiAuthenticationService = API.BE + "/user"

    func editNewPassword(password: String) async throws -> User {
        let userId = UserDefaults.standard.value(forKey: UserDefaultType.userId.rawValue)

        let response: APIResponse<User> = try await NetworkHelper.shared.update(
            urlString: apiAuthenticationService + "/update-user/\(String(describing: userId))",
            body: password
        )

        return response.data
    }

    func editNewPIN(pin: String) async throws {}

    func activateFaceID() async throws {}
}
