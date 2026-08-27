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
    var userId: String?
    var email: String?
    var hasAccessPin: Bool?
    var newAccessPin: String?
}

struct UserUpdateAccessPinBody: Codable {
    var newAccessPin: String
    var previousAccessPin: String
}

struct CreateAccessPinResponse: Codable {
    var accessPin: String?
    var hasAccessPin: Bool?
}

struct RegisterUserBody: Codable {
    let name: String
    let email: String
    let healthFacilityName: String
    let healthFacilityType: String
}

struct RegisterUserData: Codable {
    let userId: String
    let email: String
    let currentPassword: String?
}

struct DeleteAccessPinResponse: Codable {
    let accessPin: String?
    let hasAccessPin: Bool?
}

class AuthenticationInteractor: ObservableObject {
    private var modelContext: ModelContext
    private let networkService: NetworkServiceProtocol

    init(modelContext: ModelContext, networkService: NetworkServiceProtocol = DependencyInjection.shared.networkService) {
        self.modelContext = modelContext
        self.networkService = networkService
    }

    private let apiAuthenticationService = API.BE + "/user"


    func registerUser(name: String, email: String, healthFacilityName: String, healthFacilityType: String) async throws -> RegisterUserData {
        let body = RegisterUserBody(name: name, email: email, healthFacilityName: healthFacilityName, healthFacilityType: healthFacilityType)
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
        let user = User(
            id: source.id,
            name: source.name,
            role: source.role,
            healthFacilityName: source.healthFacilityName,
            email: source.email,
            accessPin: source.accessPin ?? KeychainHelper.string(for: .accessPin),
            isFaceIdEnabled: source.isFaceIdEnabled,
            businessModel: source.businessModel
        )
        return user
    }

    private func applyUser(_ source: User, to target: User) {
        target.id = source.id
        target.name = source.name
        target.role = source.role
        target.healthFacilityName = source.healthFacilityName
        target.email = source.email
        target.isFaceIdEnabled = source.isFaceIdEnabled
        target.businessModel = source.businessModel
        // Secrets: keep Keychain PIN; never write password/token to SwiftData.
        if let pin = source.accessPin, !pin.isEmpty {
            KeychainHelper.set(pin, for: .accessPin)
        }
        target.scrubSecretsForPersistence()
    }

    private func getUserSwiftData() async -> User? {
        await MainActor.run {
            let fetchDescriptor = FetchDescriptor<User>()
            do {
                let localData = try modelContext.fetch(fetchDescriptor)
                guard let user = localData.first else { return nil }

                // One-time migration: move any leftover SwiftData PIN into Keychain.
                if let legacyPin = user.accessPin, !legacyPin.isEmpty,
                   KeychainHelper.string(for: .accessPin) == nil {
                    KeychainHelper.set(legacyPin, for: .accessPin)
                }
                if user.password != nil || user.token != nil || user.previousPassword != nil || user.accessPin != nil {
                    user.scrubSecretsForPersistence()
                    try? modelContext.save()
                }
                user.loadAccessPinFromKeychain()
                return user
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
                if let pin = data.accessPin, !pin.isEmpty {
                    KeychainHelper.set(pin, for: .accessPin)
                }
                if let current = existing.first {
                    applyUser(data, to: current)
                } else {
                    let copy = copyUser(from: data)
                    copy.scrubSecretsForPersistence()
                    modelContext.insert(copy)
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
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw URLError(.userAuthenticationRequired)
        }

        let response: APIResponse<UserUpdateAccessPinResponse> = try await networkService.update(
            urlString: apiAuthenticationService + "/update-user-accessPin/\(userId)",
            headers: try authorizationHeaders(),
            body: UserUpdateAccessPinBody(
                newAccessPin: newAccessPin,
                previousAccessPin: previousAccessPin
            )
        )

        KeychainHelper.set(newAccessPin, for: .accessPin)

        return UserUpdateAccessPinResponse(
            userId: response.data.userId ?? userId,
            email: response.data.email,
            hasAccessPin: true,
            newAccessPin: newAccessPin
        )
    }

    func createAccessPin(accessPin: String) async throws -> CreateAccessPinResponse {
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw URLError(.userAuthenticationRequired)
        }

        let _: APIResponse<CreateAccessPinResponse> = try await networkService.post(
            urlString: apiAuthenticationService + "/create-user-accessPin/\(userId)",
            headers: try authorizationHeaders(),
            body: CreateAccessPinResponse(accessPin: accessPin, hasAccessPin: true)
        )

        KeychainHelper.set(accessPin, for: .accessPin)
        return CreateAccessPinResponse(accessPin: accessPin, hasAccessPin: true)
    }

    func deleteAccessPin() async throws -> DeleteAccessPinResponse {
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw URLError(.userAuthenticationRequired)
        }

        struct EmptyBody: Codable {}

        let _: APIResponse<DeleteAccessPinResponse> = try await networkService.delete(
            urlString: apiAuthenticationService + "/delete-user-accessPin/\(userId)",
            headers: try authorizationHeaders(),
            body: EmptyBody()
        )

        KeychainHelper.remove(.accessPin)
        return DeleteAccessPinResponse(accessPin: nil, hasAccessPin: false)
    }
}
