import SwiftData
import XCTest
@testable import Oculab

final class EmailVerificationTests: XCTestCase {
    @MainActor
    private func withFixture(_ body: (EmailFixture) async throws -> Void) async throws {
        let secretKeys: [KeychainKey] = [.accessToken, .refreshToken, .accessPin]
        let secrets = secretKeys.map { ($0, KeychainHelper.string(for: $0)) }
        let defaults = UserDefaultType.allCases.map { ($0, UserDefaults.standard.object(forKey: $0.rawValue)) }
        let trackingKeys = ["tracked_analysis_examination_ids", "pending_resume_analysis_examination_id"]
        let tracking = trackingKeys.map { ($0, UserDefaults.standard.object(forKey: $0)) }
        defer {
            AuthSessionManager.beginSessionChange()
            for (key, value) in secrets {
                if let value { KeychainHelper.set(value, for: key) }
                else { KeychainHelper.remove(key) }
            }
            for (key, value) in defaults { UserDefaults.standard.set(value, forKey: key.rawValue) }
            for (key, value) in tracking { UserDefaults.standard.set(value, forKey: key) }
            AuthSessionManager.completeSessionChange()
        }
        EmailFixture.setSession(owner: "email-owner-a")
        try await body(EmailFixture())
    }

    @MainActor
    func testVerifiedServerAccountSurvivesFirstCacheInsert() async throws {
        try await withFixture { f in
            f.network.response = { _, _ in try EmailFixture.payload(owner: "email-owner-a", verified: true) }
            let returned = try await f.interactor.getAccountById()
            XCTAssertTrue(returned.emailVerified, "Verified server data must not be replaced by a false transient default")
            XCTAssertEqual(returned.id, "email-owner-a")
            let cached = try XCTUnwrap(f.context.fetch(FetchDescriptor<User>()).first)
            // SwiftData can fault a newly inserted copy after it is released.
            // @Transient verification then defaults to false on re-fetch; only
            // the authoritative API user above determines clinical access.
            XCTAssertEqual(cached.id, "email-owner-a")
            XCTAssertEqual(cached.name, "Server account")
            XCTAssertEqual(cached.role, .LAB)
            XCTAssertEqual(cached.businessModel, .B2C)
            XCTAssertEqual(f.network.requestCount, 1)
        }
    }

    @MainActor
    func testVerifiedServerAccountUpdatesPreviouslyUnverifiedCache() async throws {
        try await withFixture { f in
            let cached = f.insertUser(verified: false)
            f.network.response = { _, _ in try EmailFixture.payload(owner: "email-owner-a", verified: true, name: "Updated account") }
            let returned = try await f.interactor.getAccountById()
            XCTAssertTrue(returned.emailVerified)
            XCTAssertTrue(cached.emailVerified, "The existing cache object must receive the authoritative flag")
            XCTAssertEqual(cached.name, "Updated account")
            XCTAssertEqual(try f.context.fetchCount(FetchDescriptor<User>()), 1)
        }
    }

    @MainActor
    func testAuthoritativeUnverifiedResponseClearsPreviouslyVerifiedCache() async throws {
        try await withFixture { f in
            let cached = f.insertUser(verified: true)
            f.network.response = { _, _ in try EmailFixture.payload(owner: "email-owner-a", verified: false) }
            let returned = try await f.interactor.getAccountById()
            XCTAssertFalse(returned.emailVerified)
            XCTAssertFalse(cached.emailVerified)
        }
    }

    @MainActor
    func testClinicalGateUsesAuthoritativeVerifiedAndUnverifiedAccount() async throws {
        try await withFixture { f in
            for verified in [true, false] {
                f.network.response = { _, _ in try EmailFixture.payload(owner: "email-owner-a", verified: verified) }
                await f.presenter.getAccountById()
                XCTAssertEqual(f.presenter.user.emailVerified, verified)
                XCTAssertEqual(f.presenter.isEmailVerified, verified)
                XCTAssertEqual(f.presenter.canPerformClinicalActions, verified)
                f.presenter.showEmailVerificationAlert = false
                XCTAssertEqual(f.presenter.requireEmailVerificationForClinicalAction(), verified)
                XCTAssertEqual(f.presenter.showEmailVerificationAlert, !verified)
            }
        }
    }

    @MainActor
    func testRefreshUnlocksVerifiedAccountWithoutResettingPINOrLoginFlow() async throws {
        try await withFixture { f in
            f.presenter.user = f.insertUser(verified: false)
            f.presenter.isEmailVerified = false
            f.presenter.isLogin = true
            f.presenter.isPinAuthorized = true
            f.presenter.inputPin = "2468"
            f.presenter.firstPin = "1357"
            f.presenter.secondPin = "1357"
            f.presenter.oldAccessPin = "old-pin"
            f.presenter.newAccessPin = "new-pin"
            f.presenter.state = .revalidate
            let gate = EmailResponseGate()
            let started = expectation(description: "Verification status refresh started")
            f.network.response = { _, _ in
                started.fulfill()
                await gate.wait()
                return try EmailFixture.payload(owner: "email-owner-a", verified: true)
            }
            let refresh = Task { await f.presenter.refreshEmailVerificationStatus() }
            await fulfillment(of: [started], timeout: 2)
            XCTAssertTrue(f.presenter.isRefreshingEmailVerification)
            XCTAssertFalse(f.presenter.canPerformClinicalActions)
            await gate.open()
            await refresh.value

            XCTAssertTrue(f.presenter.user.emailVerified)
            XCTAssertTrue(f.presenter.isEmailVerified)
            XCTAssertTrue(f.presenter.canPerformClinicalActions)
            XCTAssertTrue(f.presenter.isLogin)
            XCTAssertTrue(f.presenter.isPinAuthorized)
            XCTAssertEqual(f.presenter.inputPin, "2468")
            XCTAssertEqual(f.presenter.firstPin, "1357")
            XCTAssertEqual(f.presenter.secondPin, "1357")
            XCTAssertEqual(f.presenter.oldAccessPin, "old-pin")
            XCTAssertEqual(f.presenter.newAccessPin, "new-pin")
            if case .revalidate = f.presenter.state {} else { XCTFail("Refresh must preserve the PIN flow") }
            XCTAssertEqual(KeychainHelper.string(for: .accessPin), "2468")
            XCTAssertTrue(UserDefaults.standard.bool(forKey: UserDefaultType.isPinSessionAuthorized.rawValue))
            XCTAssertFalse(f.presenter.isRefreshingEmailVerification)
            XCTAssertTrue(f.presenter.emailVerificationRefreshError.isEmpty)
        }
    }

    @MainActor
    func testFailedRefreshPreservesVerifiedAccessAndShowsRefreshError() async throws {
        try await withFixture { f in
            f.presenter.user = f.insertUser(verified: true)
            f.presenter.isEmailVerified = true
            f.presenter.isLogin = true
            f.presenter.isPinAuthorized = true
            f.presenter.inputPin = "2468"
            f.network.response = { _, _ in throw URLError(.timedOut) }
            await f.presenter.refreshEmailVerificationStatus()
            XCTAssertTrue(f.presenter.isEmailVerified)
            XCTAssertTrue(f.presenter.user.emailVerified)
            XCTAssertTrue(f.presenter.canPerformClinicalActions)
            XCTAssertTrue(f.presenter.isPinAuthorized)
            XCTAssertTrue(f.presenter.isLogin)
            XCTAssertEqual(f.presenter.inputPin, "2468")
            XCTAssertFalse(f.presenter.emailVerificationRefreshError.isEmpty)
            XCTAssertFalse(f.presenter.isRefreshingEmailVerification)
            XCTAssertTrue(try XCTUnwrap(f.context.fetch(FetchDescriptor<User>()).first).emailVerified)
        }
    }

    @MainActor
    func testRefreshCopiesBusinessModelAndB2BBypassesUnverifiedEmail() async throws {
        try await withFixture { f in
            f.presenter.user = f.insertUser(verified: false)
            f.presenter.isEmailVerified = false
            XCTAssertFalse(f.presenter.canPerformClinicalActions)
            f.network.response = { _, _ in try EmailFixture.payload(owner: "email-owner-a", verified: false, model: .B2B) }
            await f.presenter.refreshEmailVerificationStatus()
            XCTAssertFalse(f.presenter.isEmailVerified)
            XCTAssertFalse(f.presenter.user.emailVerified)
            XCTAssertEqual(f.presenter.user.businessModel, .B2B)
            XCTAssertTrue(f.presenter.canPerformClinicalActions)
            XCTAssertTrue(f.presenter.requireEmailVerificationForClinicalAction())
        }
    }

    @MainActor
    func testLateVerifiedResponseAfterLogoutCannotRestoreUserOrVerification() async throws {
        try await withFixture { f in
            f.presenter.user = f.insertUser(verified: false)
            f.presenter.isEmailVerified = false
            let gate = EmailResponseGate()
            let started = expectation(description: "Refresh held until after logout")
            f.network.response = { _, _ in
                started.fulfill()
                await gate.wait()
                return try EmailFixture.payload(owner: "email-owner-a", verified: true, model: .B2B)
            }
            let refresh = Task { await f.presenter.refreshEmailVerificationStatus() }
            await fulfillment(of: [started], timeout: 2)
            await f.presenter.performLogout()
            await gate.open()
            await refresh.value
            XCTAssertFalse(f.presenter.isEmailVerified)
            XCTAssertFalse(f.presenter.user.emailVerified)
            XCTAssertFalse(f.presenter.canPerformClinicalActions)
            XCTAssertTrue(f.presenter.user.id.isEmpty)
            XCTAssertEqual(try f.context.fetchCount(FetchDescriptor<User>()), 0)
            XCTAssertNil(AuthSessionManager.uploadQueueSession)
            XCTAssertTrue(f.presenter.emailVerificationRefreshError.isEmpty)
        }
    }

    @MainActor
    func testLateOldAccountRefreshCannotOverwriteNewAccountCacheOrPresenter() async throws {
        try await withFixture { f in
            f.presenter.user = f.insertUser(verified: false)
            f.presenter.isEmailVerified = false
            let gate = EmailResponseGate()
            let started = expectation(description: "Old account response held")
            f.network.response = { _, _ in
                started.fulfill()
                await gate.wait()
                return try EmailFixture.payload(owner: "email-owner-a", verified: true, model: .B2B)
            }
            let refresh = Task { await f.presenter.refreshEmailVerificationStatus() }
            await fulfillment(of: [started], timeout: 2)
            EmailFixture.setSession(owner: "email-owner-b")
            for user in try f.context.fetch(FetchDescriptor<User>()) { f.context.delete(user) }
            let current = f.insertUser(owner: "email-owner-b", verified: false)
            f.presenter.user = current
            f.presenter.isEmailVerified = false
            await gate.open()
            await refresh.value
            XCTAssertEqual(f.presenter.user.id, "email-owner-b")
            XCTAssertFalse(f.presenter.user.emailVerified)
            XCTAssertFalse(f.presenter.isEmailVerified)
            XCTAssertEqual(f.presenter.user.businessModel, .B2C)
            XCTAssertFalse(f.presenter.canPerformClinicalActions)
            let cached = try f.context.fetch(FetchDescriptor<User>())
            XCTAssertEqual(cached.map(\.id), ["email-owner-b"])
            XCTAssertFalse(try XCTUnwrap(cached.first).emailVerified)
            XCTAssertEqual(KeychainHelper.string(for: .accessToken), "email-owner-b-access")
            XCTAssertTrue(f.presenter.emailVerificationRefreshError.isEmpty)
        }
    }

    @MainActor
    func testMismatchedServerIdentityCannotPersistVerifiedAccount() async throws {
        try await withFixture { f in
            let cached = f.insertUser(verified: false)
            f.network.response = { _, _ in try EmailFixture.payload(owner: "unrelated-user", verified: true, model: .B2B) }
            do {
                _ = try await f.interactor.getAccountById()
                XCTFail("Authenticated account fetch must reject a different returned user")
            } catch {}
            XCTAssertEqual(cached.id, "email-owner-a")
            XCTAssertFalse(cached.emailVerified)
            XCTAssertEqual(cached.businessModel, .B2C)
        }
    }

    @MainActor
    func testResetClearsVerificationAndRefreshState() async throws {
        try await withFixture { f in
            f.presenter.user = f.insertUser(verified: true, model: .B2B)
            f.presenter.isEmailVerified = true
            f.network.response = { _, _ in throw URLError(.timedOut) }
            await f.presenter.refreshEmailVerificationStatus()
            XCTAssertFalse(f.presenter.emailVerificationRefreshError.isEmpty)
            f.presenter.resetAuthenticationState()
            XCTAssertFalse(f.presenter.isEmailVerified)
            XCTAssertFalse(f.presenter.user.emailVerified)
            XCTAssertFalse(f.presenter.canPerformClinicalActions)
            XCTAssertFalse(f.presenter.isRefreshingEmailVerification)
            XCTAssertTrue(f.presenter.emailVerificationRefreshError.isEmpty)
        }
    }
}

@MainActor
private final class EmailFixture {
    let context: ModelContext
    let network = EmailVerificationNetwork()
    let interactor: AuthenticationInteractor
    let presenter: AuthenticationPresenter

    init() throws {
        let schema = Schema([User.self, PendingUpload.self])
        context = ModelContext(try ModelContainer(
            for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        ))
        interactor = AuthenticationInteractor(modelContext: context, networkService: network)
        presenter = AuthenticationPresenter(interactor: interactor)
        network.response = { _, _ in try Self.payload(owner: "email-owner-a", verified: false) }
    }

    func insertUser(owner: String = "email-owner-a", verified: Bool, model: BusinessModelType = .B2C) -> User {
        let user = User(id: owner, name: "Cached account", role: .LAB, businessModel: model, emailVerified: verified)
        context.insert(user)
        do { try context.save() } catch { XCTFail("In-memory user fixture could not be saved: \(error)") }
        return user
    }

    static func setSession(owner: String) {
        AuthSessionManager.beginSessionChange()
        XCTAssertTrue(KeychainHelper.set("\(owner)-access", for: .accessToken))
        XCTAssertTrue(KeychainHelper.set("\(owner)-refresh", for: .refreshToken))
        XCTAssertTrue(KeychainHelper.set("2468", for: .accessPin))
        UserDefaults.standard.set(owner, forKey: UserDefaultType.userId.rawValue)
        UserDefaults.standard.set(true, forKey: UserDefaultType.isUserLoggedIn.rawValue)
        AuthSessionManager.completeSessionChange()
    }

    static func payload(owner: String, verified: Bool, name: String = "Server account", model: BusinessModelType = .B2C) throws -> Data {
        try JSONSerialization.data(withJSONObject: [
            "status": "success", "code": 200, "message": "Account retrieved", "data": [
                "id": owner, "name": name, "role": "LAB", "email": "user@example.invalid",
                "businessModel": model.rawValue, "emailVerified": verified
            ]
        ])
    }
}

private final class EmailVerificationNetwork: MockNetworkService {
    var response: (@MainActor (String, [String: String]?) async throws -> Data)!
    @MainActor private(set) var requestCount = 0

    override func get<T: Decodable>(urlString: String, headers: [String: String]?) async throws -> APIResponse<T> {
        await MainActor.run { requestCount += 1 }
        guard urlString.contains("/user/get-user-data-by-id/") else {
            throw URLError(.unsupportedURL)
        }
        return try JSONDecoder().decode(APIResponse<T>.self, from: await response(urlString, headers))
    }
}

private actor EmailResponseGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var isOpen = false
    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { continuation = $0 }
    }
    func open() {
        isOpen = true
        continuation?.resume()
        continuation = nil
    }
}
