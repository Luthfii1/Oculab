//
//  AuthSessionManager.swift
//  Oculab
//

import Foundation

struct UploadQueueSession: Equatable {
    let ownerUserId: String
    let generation: UUID
}

struct RefreshTokenBody: Codable {
    let tokenUserId: String
}

struct RefreshTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
}

enum AuthSessionManager {
    static let sessionDidInvalidateNotification = Notification.Name("oculab.auth.sessionDidInvalidate")
    static let invalidatedSessionGenerationKey = "sessionGeneration"
    static let sessionDidChangeNotification = Notification.Name("oculab.auth.sessionDidChange")
    @MainActor private static var sessionGeneration = UUID()
    @MainActor private static var isChangingSession = false
    @MainActor static var authenticationSessionGeneration: UUID { sessionGeneration }

    @MainActor static var uploadQueueSession: UploadQueueSession? {
        guard !isChangingSession,
              UserDefaults.standard.bool(forKey: UserDefaultType.isUserLoggedIn.rawValue),
              let owner = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue),
              !owner.isEmpty,
              KeychainHelper.string(for: .accessToken) != nil else { return nil }
        return UploadQueueSession(ownerUserId: owner.lowercased(), generation: sessionGeneration)
    }

    /// Cancel queued work before changing credentials, including same-account relogin.
    @MainActor static func beginSessionChange() {
        isChangingSession = true
        sessionGeneration = UUID()
        AnalysisRealtimeService.shared.resetSession()
        NotificationCenter.default.post(name: sessionDidChangeNotification, object: nil)
    }

    @MainActor static func completeSessionChange() {
        isChangingSession = false
        NotificationCenter.default.post(name: sessionDidChangeNotification, object: nil)
    }

    private static let unauthenticatedPaths = [
        "/user/login",
        "/user/register",
        "/user/refresh-token/",
        "/user/request-reset-password-by-email",
        "/user/reset-password",
        "/user/verify-email",
        "/user/request-email-verification",
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
        using networkService: NetworkServiceProtocol = DependencyInjection.shared.networkService,
        expectedGeneration: UUID? = nil
    ) async throws {
        let (refreshToken, userId, generation) = try await MainActor.run {
            if let expectedGeneration, expectedGeneration != sessionGeneration { throw CancellationError() }
            guard !isChangingSession,
                  let refreshToken = KeychainHelper.string(for: .refreshToken),
                  let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
                throw URLError(.userAuthenticationRequired)
            }
            return (refreshToken, userId, sessionGeneration)
        }

        let headers = bearerHeaders(accessToken: refreshToken)
        let body = RefreshTokenBody(tokenUserId: userId)
        let url = API.BE + "/user/refresh-token/\(userId)"

        let response: APIResponse<RefreshTokenResponse> = try await networkService.post(
            urlString: url,
            headers: headers,
            body: body
        )

        try await MainActor.run {
            guard generation == sessionGeneration,
                  UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) == userId,
                  KeychainHelper.string(for: .refreshToken) == refreshToken else { throw CancellationError() }
            KeychainHelper.set(response.data.accessToken, for: .accessToken)
            if let newRefresh = response.data.refreshToken, !newRefresh.isEmpty {
                KeychainHelper.set(newRefresh, for: .refreshToken)
            }
        }
    }

    /// Clears local auth state and notifies the UI to return to login.
    @MainActor
    static func invalidateSession(ifGeneration generation: UUID) throws {
        guard generation == sessionGeneration else { throw CancellationError() }
        invalidateSession()
    }

    @MainActor
    static func invalidateSession() {
        beginSessionChange()
        defer { completeSessionChange() }
        UserDefaults.standard.set(false, forKey: UserDefaultType.isUserLoggedIn.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultType.userId.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultType.isPinSessionAuthorized.rawValue)
        KeychainHelper.removeAll()
        NotificationCenter.default.post(
            name: sessionDidInvalidateNotification, object: nil,
            userInfo: [invalidatedSessionGenerationKey: sessionGeneration]
        )
    }
}

actor AuthTokenRefresher {
    static let shared = AuthTokenRefresher()

    private var refreshTask: Task<Void, Error>?
    private var refreshGeneration: UUID?
    private var refreshID: UUID?

    func refreshAccessToken(
        using networkService: NetworkServiceProtocol = DependencyInjection.shared.networkService,
        expectedGeneration: UUID? = nil
    ) async throws {
        let generation = await MainActor.run { AuthSessionManager.authenticationSessionGeneration }
        if let expectedGeneration, expectedGeneration != generation { throw CancellationError() }
        if let refreshTask, refreshGeneration == generation {
            try await refreshTask.value
            return
        }

        refreshTask?.cancel()

        let task = Task {
            try await AuthSessionManager.refreshAccessToken(using: networkService, expectedGeneration: generation)
        }
        refreshTask = task
        refreshGeneration = generation
        let id = UUID()
        refreshID = id
        defer {
            if refreshID == id {
                refreshTask = nil
                refreshGeneration = nil
                refreshID = nil
            }
        }
        try await task.value
    }
}
