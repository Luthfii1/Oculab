//
//  ProfileInteractor.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/11/24.
//

import Foundation

struct UserUpdatePasswordResponse: Codable {
    var userId: String
    var email: String
    var newPassword: String
}

struct UserUpdatePasswordBody: Codable {
    var newPassword: String
    var previousPassword: String
}

protocol ProfileInteractorProtocol {
    func editNewPassword(newPassword: String, previousPassword: String) async throws -> UserUpdatePasswordResponse
//    func editNewPIN(newAccessPin: String, previousAccessPin: String) async throws -> UserUpdateAccessPinResponse
    func activateFaceID() async throws
}

class ProfileInteractor: ProfileInteractorProtocol {
    private let apiAuthenticationService = API.BE + "/user"

    func editNewPassword(newPassword: String, previousPassword: String) async throws -> UserUpdatePasswordResponse {
        guard let token = UserDefaults.standard.string(forKey: UserDefaultType.accessToken.rawValue) else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
                throw URLError(.userAuthenticationRequired)
            }
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        let response: APIResponse<UserUpdatePasswordResponse> = try await NetworkHelper.shared.update(
            urlString: apiAuthenticationService + "/update-user-password/\(String(describing: userId))",
            body: UserUpdatePasswordBody(
                newPassword: newPassword,
                previousPassword: previousPassword
            ),
            headers: headers
        )

        return UserUpdatePasswordResponse(
            userId: response.data.userId,
            email: response.data.email,
            newPassword: response.data.newPassword
        )
    }

    func activateFaceID() async throws {}
}
