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


class AuthenticationInteractor: ObservableObject {
    private var modelContext: ModelContext
    private let networkService: NetworkService

    init(modelContext: ModelContext, networkService: NetworkService = AlamofireNetworkService()) {
        self.modelContext = modelContext
        self.networkService = networkService
    }

    private let apiAuthenticationService = API.BE + "/user"

    func login(email: String, password: String) async throws -> LoginResponse {
        let response: APIResponse<LoginResponse> = try await networkService.post(
            urlString: apiAuthenticationService + "/login",
            headers: nil,
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
                domain: "AuthenticationError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Please login first to access user data"]
            )
        }

        let response: APIResponse<User> = try await networkService.get(
            urlString: apiAuthenticationService + "/get-user-data-by-id/\(userId)",
            headers: nil
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

        let response: APIResponse<User> = try await networkService.update(
            urlString: apiAuthenticationService + "/update-user/\(userId)",
            headers: nil,
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
        await MainActor.run {
            modelContext.insert(data)
            do {
                try modelContext.save()
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    private func getUserSwiftData() async -> User? {
        await MainActor.run {
            let fetchDescriptor = FetchDescriptor<User>()
            do {
                let localData = try modelContext.fetch(fetchDescriptor)
                return localData.first
            } catch {
                print("Error: \(error.localizedDescription)")
                return nil
            }
        }
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
    
    func editNewPIN(newAccessPin: String, previousAccessPin: String) async throws -> UserUpdateAccessPinResponse {
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
        
        let response: APIResponse<UserUpdateAccessPinResponse> = try await networkService.update(
            urlString: apiAuthenticationService + "/update-user-accessPin/\(String(describing: userId))",
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
        
        let response: APIResponse<CreateAccessPinResponse> = try await networkService.post(
            urlString: apiAuthenticationService + "/create-user-accessPin/\(String(describing: userId))",
            headers: headers,
            body: CreateAccessPinResponse(accessPin: accessPin)
        )
        
        return CreateAccessPinResponse(accessPin: response.data.accessPin)
    }
}
