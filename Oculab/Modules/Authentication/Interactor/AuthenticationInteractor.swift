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

class AuthenticationInteractor: ObservableObject {
    private var modelContext: ModelContext
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

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

        // save to swiftdata
        await updateUserSwiftData(data: response.data)

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

        let response: APIResponse<User> = try await NetworkHelper.shared.update(
            urlString: apiAuthenticationService + "/update-user/\(userId)",
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

    private func insertUserSwiftData(data: User) async {
        modelContext.insert(data)

        do {
            try modelContext.save()
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }

    private func getUserSwiftData() async -> User? {
        let fetchDescriptor = FetchDescriptor<User>()

        do {
            let localData = try modelContext.fetch(fetchDescriptor)
            return localData.first ?? nil
        } catch {
            print("Error: \(error.localizedDescription)")
        }

        return nil
    }

    private func updateUserSwiftData(data: User) async {
        await removeUserSwiftData()
        await insertUserSwiftData(data: data)
    }

    private func removeUserSwiftData() async {
        let fetchDescriptor = FetchDescriptor<User>()

        do {
            let allUsers = try modelContext.fetch(fetchDescriptor)

            for user in allUsers {
                modelContext.delete(user)
            }

            try modelContext.save()
        } catch {
            print("Error deleting all users: \(error.localizedDescription)")
        }
    }
}
