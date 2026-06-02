//
//  AuthenticationInteractor.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 06/11/24.
//

import Foundation
import SwiftData

struct UserBody: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let userId: String
}

struct UserUpdateAccessPinResponse: Codable {
    var userId: String
    var email: String
    var newAccessPin: String
}

struct UserUpdateAccessPinBody: Codable {
    var newAccessPin: String
    var previousAccessPin: String
}

struct CreateAccessPinResponse: Codable {
    var accessPin: String
}

struct RegisterUserBody: Codable {
    let _id: String?
    let name: String
    let email: String
    let healthFacilityName: String
    let healthFacilityType: String
}

struct RegisterUserData: Codable {
    let userId: String
    let email: String
    let currentPassword: String
}

struct DeleteAccessPinResponse: Codable {
    let accessPin: String?
}

class AuthenticationInteractor: ObservableObject {
    private var modelContext: ModelContext
    private let networkService: NetworkServiceProtocol

    init(modelContext: ModelContext, networkService: NetworkServiceProtocol = AlamofireNetworkService()) {
        self.modelContext = modelContext
        self.networkService = networkService
    }

    private let apiAuthenticationService = API.BE + "/user"


    func registerUser(name: String, email: String, healthFacilityName: String, healthFacilityType: String) async throws -> RegisterUserData {
        let body = RegisterUserBody(_id: nil, name: name, email: email, healthFacilityName: healthFacilityName, healthFacilityType: healthFacilityType)
        let response: APIResponse<RegisterUserData> = try await networkService.post(
            urlString: apiAuthenticationService + "/register",
            headers: nil,
            body: body
        )
        return response.data
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        let response: APIResponse<LoginResponse> = try await networkService.post(
            urlString: apiAuthenticationService + "/login",
            headers: nil,
            body: UserBody(email: email, password: password)
        )

        // Store credentials in Keychain; non-secret state in UserDefaults.
        KeychainHelper.set(response.data.accessToken, for: .accessToken)
        KeychainHelper.set(response.data.refreshToken, for: .refreshToken)
        UserDefaults.standard.set(true, forKey: UserDefaultType.isUserLoggedIn.rawValue)
        UserDefaults.standard.set(false, forKey: UserDefaultType.isPinSessionAuthorized.rawValue)
        UserDefaults.standard.set(response.data.userId, forKey: UserDefaultType.userId.rawValue)

        return response.data
    }

    func getAccountById() async throws -> User {
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw NSError(
                domain: "AuthenticationError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Please login first to access user data"]
            )
        }

        let response: APIResponse<User> = try await networkService.get(
            urlString: apiAuthenticationService + "/get-user-data-by-id/\(userId)",
            headers: try authorizationHeaders()
        )

        await updateUserSwiftData(data: response.data)

        if let localUser = await getUserSwiftData() {
            return localUser
        }
        return response.data
    }

    func updateUserById(user: User) async throws -> User {
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw NSError(
                domain: "UserIdNotFound",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "User ID not found"]
            )
        }

        let response: APIResponse<User> = try await networkService.update(
            urlString: apiAuthenticationService + "/update-user/\(userId)",
            headers: try authorizationHeaders(),
            body: user
        )

        await updateUserSwiftData(data: response.data)

        return response.data
    }

    func getUserLocalData() async -> User? {
        return await getUserSwiftData()
    }

    func updateUserLocalData(user: User) async {
        await updateUserSwiftData(data: user)
    }

    func clearLocalUserData() async {
        await removeUserSwiftData()
    }

    private func authorizationHeaders() throws -> [String: String] {
        try AuthSessionManager.authorizationHeaders()
    }

    private func copyUser(from source: User) -> User {
        User(
            _id: source._id,
            name: source.name,
            role: source.role,
            token: source.token,
            healthFacilityName: source.healthFacilityName,
            email: source.email,
            password: source.password,
            previousPassword: source.previousPassword,
            accessPin: source.accessPin,
            isFaceIdEnabled: source.isFaceIdEnabled,
            businessModel: source.businessModel
        )
    }

    private func applyUser(_ source: User, to target: User) {
        target._id = source._id
        target.name = source.name
        target.role = source.role
        target.token = source.token
        target.healthFacilityName = source.healthFacilityName
        target.email = source.email
        target.password = source.password
        target.previousPassword = source.previousPassword
        target.accessPin = source.accessPin
        target.isFaceIdEnabled = source.isFaceIdEnabled
        target.businessModel = source.businessModel
    }

    private func getUserSwiftData() async -> User? {
        await MainActor.run {
            let fetchDescriptor = FetchDescriptor<User>()
            do {
                let localData = try modelContext.fetch(fetchDescriptor)
                return localData.first
            } catch {
                Logger.error("Failed to fetch user from SwiftData: \(error.localizedDescription)", category: .authentication)
                return nil
            }
        }
    }

    private func updateUserSwiftData(data: User) async {
        await MainActor.run {
            let fetchDescriptor = FetchDescriptor<User>()
            do {
                let existing = try modelContext.fetch(fetchDescriptor)
                if let current = existing.first {
                    applyUser(data, to: current)
                } else {
                    modelContext.insert(copyUser(from: data))
                }
                try modelContext.save()
            } catch {
                Logger.error("Failed to update user in SwiftData: \(error.localizedDescription)", category: .authentication)
            }
        }
    }

    private func removeUserSwiftData() async {
        await MainActor.run {
            let fetchDescriptor = FetchDescriptor<User>()

            do {
                let allUsers = try modelContext.fetch(fetchDescriptor)

                for user in allUsers {
                    modelContext.delete(user)
                }

                try modelContext.save()
            } catch {
                Logger.error("Failed to delete all users: \(error.localizedDescription)", category: .authentication)
            }
        }
    }
    
    func editNewPIN(newAccessPin: String, previousAccessPin: String) async throws -> UserUpdateAccessPinResponse {
        guard let token = KeychainHelper.string(for: .accessToken) else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw URLError(.userAuthenticationRequired)
        }
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        let response: APIResponse<UserUpdateAccessPinResponse> = try await networkService.update(
            urlString: apiAuthenticationService + "/update-user-accessPin/\(userId)",
            headers: headers,
            body: UserUpdateAccessPinBody(
                newAccessPin: newAccessPin,
                previousAccessPin: previousAccessPin
            )
        )

        return UserUpdateAccessPinResponse(
            userId: response.data.userId,
            email: response.data.email,
            newAccessPin: response.data.newAccessPin
        )
    }
    
    func createAccessPin(accessPin: String) async throws -> CreateAccessPinResponse {
        guard let token = KeychainHelper.string(for: .accessToken) else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw URLError(.userAuthenticationRequired)
        }
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        let response: APIResponse<CreateAccessPinResponse> = try await networkService.post(
            urlString: apiAuthenticationService + "/create-user-accessPin/\(userId)",
            headers: headers,
            body: CreateAccessPinResponse(accessPin: accessPin)
        )
        
        return CreateAccessPinResponse(accessPin: response.data.accessPin)
    }

    func deleteAccessPin() async throws -> DeleteAccessPinResponse {
        guard let token = KeychainHelper.string(for: .accessToken) else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw URLError(.userAuthenticationRequired)
        }
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        struct EmptyBody: Codable {}
        
        let response: APIResponse<DeleteAccessPinResponse> = try await networkService.delete(
            urlString: apiAuthenticationService + "/delete-user-accessPin/\(userId)",
            headers: headers,
            body: EmptyBody()
        )
        
        return DeleteAccessPinResponse(accessPin: response.data.accessPin)
    }
}
