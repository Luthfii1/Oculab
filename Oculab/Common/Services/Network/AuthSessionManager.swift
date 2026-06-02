//
//  AuthSessionManager.swift
//  Oculab
//

import Foundation

struct RefreshTokenBody: Codable {
    let tokenUserId: String
}

struct RefreshTokenResponse: Codable {
    let accessToken: String
}

enum AuthSessionManager {
    private static let unauthenticatedPaths = [
        "/user/login",
        "/user/register",
        "/user/refresh-token/",
        "/user/request-reset-password-by-email",
        "/user/reset-password",
    ]

    static func authorizationHeaders() throws -> [String: String] {
        guard let token = KeychainHelper.string(for: .accessToken) else {
            throw URLError(.userAuthenticationRequired)
        }
        return bearerHeaders(accessToken: token)
    }

    static func bearerHeaders(accessToken: String) -> [String: String] {
        [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json",
        ]
    }

    static func headersByReplacingAuthorization(
        _ headers: [String: String]?
    ) throws -> [String: String] {
        var merged = headers ?? [:]
        let authHeaders = try authorizationHeaders()
        merged.merge(authHeaders) { _, new in new }
        return merged
    }

    static func requiresAuthentication(for endpoint: String) -> Bool {
        !unauthenticatedPaths.contains(where: { endpoint.contains($0) })
    }

    static func shouldAttachAuthorization(to endpoint: String) -> Bool {
        guard requiresAuthentication(for: endpoint),
              KeychainHelper.string(for: .accessToken) != nil
        else {
            return false
        }
        return true
    }

    static func shouldAttemptTokenRefresh(for endpoint: String) -> Bool {
        guard KeychainHelper.string(for: .refreshToken) != nil,
              UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) != nil
        else {
            return false
        }

        return requiresAuthentication(for: endpoint)
    }

    static func refreshAccessToken(
        using networkService: NetworkServiceProtocol = AlamofireNetworkService()
    ) async throws {
        guard let refreshToken = KeychainHelper.string(for: .refreshToken),
              let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue)
        else {
            throw URLError(.userAuthenticationRequired)
        }

        let headers = bearerHeaders(accessToken: refreshToken)
        let body = RefreshTokenBody(tokenUserId: userId)
        let url = API.BE + "/user/refresh-token/\(userId)"

        let response: APIResponse<RefreshTokenResponse> = try await networkService.post(
            urlString: url,
            headers: headers,
            body: body
        )

        KeychainHelper.set(response.data.accessToken, for: .accessToken)
    }
}

actor AuthTokenRefresher {
    static let shared = AuthTokenRefresher()

    private var refreshTask: Task<Void, Error>?

    func refreshAccessToken(
        using networkService: NetworkServiceProtocol = AlamofireNetworkService()
    ) async throws {
        if let refreshTask {
            try await refreshTask.value
            return
        }

        let task = Task {
            try await AuthSessionManager.refreshAccessToken(using: networkService)
        }
        refreshTask = task
        defer { refreshTask = nil }
        try await task.value
    }
}
