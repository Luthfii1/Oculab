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
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = DependencyInjection.shared.networkService) {
        self.networkService = networkService
    }
    
    private let apiAuthenticationService = API.BE + "/user"

    @MainActor
    func editNewPassword(newPassword: String, previousPassword: String) async throws -> UserUpdatePasswordResponse {
        guard let session = AuthSessionManager.uploadQueueSession,
              let token = KeychainHelper.string(for: .accessToken),
              let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue),
              userId.lowercased() == session.ownerUserId else {
            throw URLError(.userAuthenticationRequired)
        }
        try Task.checkCancellation()
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        let response: APIResponse<UserUpdatePasswordResponse> = try await networkService.update(
            urlString: apiAuthenticationService + "/update-user-password/\(userId)",
            headers: headers,
            body: UserUpdatePasswordBody(
                newPassword: newPassword,
                previousPassword: previousPassword
            )
        )

        try Task.checkCancellation()
        guard session == AuthSessionManager.uploadQueueSession,
              response.data.userId.lowercased() == session.ownerUserId else { throw CancellationError() }
        return response.data
    }

    func activateFaceID() async throws {}
}
