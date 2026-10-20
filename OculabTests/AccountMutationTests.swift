import SwiftData
import SwiftUI
import XCTest
@testable import Oculab

final class AccountMutationTests: XCTestCase {
    @MainActor
    private func withFixture(_ body: (AccountMutationFixture) async throws -> Void) async throws {
        let keys: [KeychainKey] = [.accessToken, .refreshToken, .accessPin]
        let secrets = keys.map { ($0, KeychainHelper.string(for: $0)) }
        let defaults = UserDefaultType.allCases.map { ($0, UserDefaults.standard.object(forKey: $0.rawValue)) }
        let trackingKeys = ["tracked_analysis_examination_ids", "pending_resume_analysis_examination_id"]
        let tracking = trackingKeys.map { ($0, UserDefaults.standard.object(forKey: $0)) }
        let path = Router.shared.path
        let route = Router.shared.currentRoute
        defer {
            AuthSessionManager.beginSessionChange()
            for (key, value) in secrets {
                if let value { KeychainHelper.set(value, for: key) }
                else { KeychainHelper.remove(key) }
            }
            for (key, value) in defaults { UserDefaults.standard.set(value, forKey: key.rawValue) }
            for (key, value) in tracking { UserDefaults.standard.set(value, forKey: key) }
            AuthSessionManager.completeSessionChange()
            Router.shared.path = path
            Router.shared.currentRoute = route
        }
        AccountMutationFixture.setSession(owner: "pin-owner-a", pin: "2468")
        UserDefaults.standard.set(false, forKey: UserDefaultType.firstTimeLogin.rawValue)
        try await body(AccountMutationFixture())
    }

    @MainActor
    func testConfirmedPINCreateUpdateAndDeleteUseSafeResponsesAndCacheSubmittedPIN() async throws {
        try await withFixture { f in
            KeychainHelper.remove(.accessPin)
            _ = try await f.interactor.createAccessPin(accessPin: "1357")
            XCTAssertEqual(KeychainHelper.string(for: .accessPin), "1357")
            XCTAssertEqual(f.network.requests.last?.path, "/user/create-user-accessPin/pin-owner-a")
            XCTAssertEqual(f.network.requests.last?.headers?["Authorization"], "Bearer pin-owner-a-access")
            let createBody = try XCTUnwrap(f.network.requests.last?.body)
            XCTAssertEqual(try XCTUnwrap(JSONSerialization.jsonObject(with: createBody) as? [String: Any])["accessPin"] as? String, "1357")

            _ = try await f.interactor.editNewPIN(newAccessPin: "8642", previousAccessPin: "1357")
            XCTAssertEqual(KeychainHelper.string(for: .accessPin), "8642")
            XCTAssertEqual(f.network.requests.last?.path, "/user/update-user-accessPin/pin-owner-a")
            let updateBody = try XCTUnwrap(f.network.requests.last?.body)
            XCTAssertEqual(try JSONSerialization.jsonObject(with: updateBody) as? [String: String], [
                "previousAccessPin": "1357", "newAccessPin": "8642"
            ])

            _ = try await f.interactor.deleteAccessPin()
            XCTAssertNil(KeychainHelper.string(for: .accessPin))
            XCTAssertEqual(f.network.requests.last?.method, "DELETE")
            XCTAssertEqual(f.network.requests.last?.path, "/user/delete-user-accessPin/pin-owner-a")
            XCTAssertEqual(KeychainHelper.string(for: .accessToken), "pin-owner-a-access")
            XCTAssertEqual(f.network.requests.count, 3)
        }
    }

    @MainActor
    func testDelayedPINCreateUpdateAndDeleteCannotChangeNewSessionOrLoggedOutKeychain() async throws {
        for mutation in AccountPINMutation.allCases {
            for logout in [false, true] {
                try await withFixture { f in
                    let started = expectation(description: "\(mutation.rawValue) response held before session change")
                    let gate = AccountMutationGate()
                    f.network.response = { request in
                        started.fulfill()
                        await gate.wait()
                        return try AccountMutationFixture.mutationPayload(hasPin: request.method != "DELETE")
                    }
                    let request = Task { try await mutation.perform(using: f.interactor) }
                    await fulfillment(of: [started], timeout: 2)
                    try await f.replaceSession(logout: logout)
                    await gate.open()
                    do {
                        try await request.value
                        XCTFail("An old account's successful mutation must be rejected after its session changes")
                    } catch is CancellationError {}

                    XCTAssertEqual(KeychainHelper.string(for: .accessPin), logout ? nil : "9753")
                    XCTAssertEqual(KeychainHelper.string(for: .accessToken), logout ? nil : "pin-owner-b-access")
                    XCTAssertEqual(AuthSessionManager.uploadQueueSession?.ownerUserId, logout ? nil : "pin-owner-b")
                    XCTAssertEqual(f.network.requests.count, 1)
                    XCTAssertEqual(f.network.requests.first?.headers?["Authorization"], "Bearer pin-owner-a-access")
                    let users = try f.context.fetch(FetchDescriptor<User>())
                    XCTAssertEqual(users.map(\.id), logout ? [] : ["pin-owner-b"])
                    if !logout { XCTAssertEqual(users.first?.name, "Current second account") }
                }
            }
        }
    }

    @MainActor
    func testLateProfileUpdateCannotReplaceNewAccountCacheOrRecreateLoggedOutUser() async throws {
        for logout in [false, true] {
            try await withFixture { f in
                let started = expectation(description: "Old profile update response held")
                let gate = AccountMutationGate()
                f.network.response = { _ in
                    started.fulfill()
                    await gate.wait()
                    return try AccountMutationFixture.userPayload(name: "Late first account", hasPin: true)
                }
                let edited = User(id: "pin-owner-a", name: "Edited first account", role: .LAB)
                let request = Task { _ = try await f.interactor.updateUserById(user: edited) }
                await fulfillment(of: [started], timeout: 2)
                try await f.replaceSession(logout: logout)
                await gate.open()
                do {
                    try await request.value
                    XCTFail("A late profile response must not be applied to a different session")
                } catch is CancellationError {}
                let users = try f.context.fetch(FetchDescriptor<User>())
                XCTAssertEqual(users.map(\.id), logout ? [] : ["pin-owner-b"])
                if !logout { XCTAssertEqual(users.first?.name, "Current second account") }
                XCTAssertEqual(KeychainHelper.string(for: .accessPin), logout ? nil : "9753")
                XCTAssertEqual(KeychainHelper.string(for: .accessToken), logout ? nil : "pin-owner-b-access")
            }
        }
    }

    @MainActor
    func testLatePresenterProfileSuccessOrFailurePreservesReplacementSessionUIAndNavigation() async throws {
        for failed in [false, true] {
            for logout in [false, true] {
                try await withFixture { f in
                    let started = expectation(description: "Presenter profile response held before session change")
                    let gate = AccountMutationGate()
                    f.network.response = { _ in
                        started.fulfill()
                        await gate.wait()
                        if failed { throw URLError(.networkConnectionLost) }
                        return try AccountMutationFixture.userPayload(name: "Late first account", hasPin: true)
                    }
                    let edited = User(id: "pin-owner-a", name: "Edited first account", role: .LAB)
                    let request = Task { await f.presenter.updateAccount(updateUser: edited) }
                    await fulfillment(of: [started], timeout: 2)
                    try await f.replaceSession(logout: logout)
                    f.presenter.errorMessage = "Current session status"
                    f.presenter.isError = false
                    f.presenter.isLoading = !logout
                    Router.shared.path = NavigationPath()
                    let replacementRoute: Router.Route = logout ? .login : .privacyPolicy
                    Router.shared.path.append(replacementRoute)
                    Router.shared.currentRoute = replacementRoute
                    await gate.open()
                    await request.value

                    XCTAssertEqual(f.presenter.user.id, logout ? "" : "pin-owner-b")
                    XCTAssertEqual(f.presenter.errorMessage, "Current session status")
                    XCTAssertFalse(f.presenter.isError)
                    XCTAssertEqual(f.presenter.isLoading, !logout, "An old request must not dismiss a new session's loading state")
                    XCTAssertEqual(Router.shared.path.count, 1)
                    XCTAssertEqual(Router.shared.currentRoute, replacementRoute)
                    XCTAssertEqual(KeychainHelper.string(for: .accessPin), logout ? nil : "9753")
                    XCTAssertEqual(KeychainHelper.string(for: .accessToken), logout ? nil : "pin-owner-b-access")
                    let users = try f.context.fetch(FetchDescriptor<User>())
                    XCTAssertEqual(users.map(\.id), logout ? [] : ["pin-owner-b"])
                    if !logout { XCTAssertEqual(users.first?.name, "Current second account") }
                }
            }
        }
    }

    @MainActor
    func testDelayedPresenterPINOperationsCannotAuthorizeOrLogoutReplacementSession() async throws {
        for mutation in AccountPINMutation.allCases {
            for logout in [false, true] {
                try await withFixture { f in
                    f.presenter.state = .revalidate
                    f.presenter.firstPin = "1357"
                    f.presenter.oldAccessPin = "2468"
                    f.presenter.newAccessPin = "8642"
                    let started = expectation(description: "Presenter \(mutation.rawValue) held until session changes")
                    let gate = AccountMutationGate()
                    f.network.response = { request in
                        started.fulfill()
                        await gate.wait()
                        return try AccountMutationFixture.mutationPayload(hasPin: request.method != "DELETE")
                    }
                    let request = Task { await mutation.perform(using: f.presenter) }
                    await fulfillment(of: [started], timeout: 2)
                    try await f.replaceSession(logout: logout)
                    if !logout {
                        f.presenter.state = .authenticate
                        f.presenter.isError = false
                        f.appState.initializationState = .requiresPinAuthentication
                    }
                    await gate.open()
                    await request.value

                    XCTAssertEqual(KeychainHelper.string(for: .accessPin), logout ? nil : "9753")
                    XCTAssertEqual(KeychainHelper.string(for: .accessToken), logout ? nil : "pin-owner-b-access")
                    XCTAssertEqual(AuthSessionManager.uploadQueueSession?.ownerUserId, logout ? nil : "pin-owner-b")
                    XCTAssertEqual(f.presenter.user.id, logout ? "" : "pin-owner-b")
                    XCTAssertFalse(f.presenter.isError, "Cancelled work from the old session must not show an error in the replacement session")
                    XCTAssertFalse(f.presenter.isPinAuthorized)
                    XCTAssertFalse(f.presenter.showAccessPinSuccessPopup)
                    XCTAssertFalse(UserDefaults.standard.bool(forKey: UserDefaultType.firstTimeLogin.rawValue))
                    XCTAssertEqual(f.appState.initializationState, logout ? .unauthenticated : .requiresPinAuthentication)
                    XCTAssertEqual(f.network.requests.count, 1)
                }
            }
        }
    }

    @MainActor
    func testCreateConflictCannotCacheUnconfirmedPINOrCompleteOnboarding() async throws {
        try await withFixture { f in
            KeychainHelper.remove(.accessPin)
            f.presenter.state = .revalidate
            f.presenter.firstPin = "1357"
            f.appState.initializationState = .requiresPinCreation
            f.network.response = { _ in
                throw NetworkError.apiError(APIResponse(
                    status: "error", code: 409, message: "Access PIN already exists",
                    data: ApiErrorData(errorType: "CONFLICT_ERROR", description: "Access PIN already exists")
                ))
            }

            await f.presenter.handlePinInput("1357")

            XCTAssertTrue(f.presenter.isError)
            XCTAssertTrue(f.presenter.user.hasAccessPin)
            XCTAssertEqual(f.presenter.descriptionPIN, AppTextAuthCompPin.pinUnavailableOnDevice)
            XCTAssertNil(KeychainHelper.string(for: .accessPin), "A conflict does not confirm the proposed PIN")
            XCTAssertNil(f.presenter.user.accessPin)
            XCTAssertFalse(f.presenter.isPinAuthorized)
            XCTAssertFalse(f.presenter.showAccessPinSuccessPopup)
            XCTAssertFalse(UserDefaults.standard.bool(forKey: UserDefaultType.firstTimeLogin.rawValue))
            XCTAssertFalse(UserDefaults.standard.bool(forKey: UserDefaultType.isPinSessionAuthorized.rawValue))
            XCTAssertNotEqual(f.appState.initializationState, .createFaceId)
            XCTAssertNotEqual(f.appState.initializationState, .authenticated)
            XCTAssertEqual(f.network.requests.filter { $0.method == "POST" }.count, 1)
        }
    }

    @MainActor
    func testSuccessfulPINEditPopupDismissalClearsCurrentSessionNavigation() async throws {
        try await withFixture { f in
            f.presenter.oldAccessPin = "2468"
            f.presenter.newAccessPin = "8642"
            Router.shared.path = NavigationPath()
            Router.shared.path.append(Router.Route.profile)
            Router.shared.path.append(Router.Route.userAccessPin(state: .changePIN))
            Router.shared.currentRoute = .userAccessPin(state: .changePIN)

            await f.presenter.editAccessPin()

            XCTAssertTrue(f.presenter.showAccessPinSuccessPopup)
            XCTAssertEqual(KeychainHelper.string(for: .accessPin), "8642")
            XCTAssertEqual(Router.shared.path.count, 2)
            f.presenter.dismissAccessPinSuccess()
            XCTAssertFalse(f.presenter.showAccessPinSuccessPopup)
            XCTAssertTrue(Router.shared.path.isEmpty)
            XCTAssertNil(Router.shared.currentRoute)
            XCTAssertEqual(AuthSessionManager.uploadQueueSession?.ownerUserId, "pin-owner-a")
            XCTAssertEqual(KeychainHelper.string(for: .accessPin), "8642")
        }
    }

    @MainActor
    func testStalePINEditPopupCannotClearReplacementAccountNavigation() async throws {
        try await withFixture { f in
            f.presenter.oldAccessPin = "2468"
            f.presenter.newAccessPin = "8642"
            await f.presenter.editAccessPin()
            XCTAssertTrue(f.presenter.showAccessPinSuccessPopup)
            try await f.replaceSession(logout: false)
            Router.shared.path = NavigationPath()
            Router.shared.path.append(Router.Route.profile)
            Router.shared.path.append(Router.Route.privacyPolicy)
            Router.shared.currentRoute = .privacyPolicy

            f.presenter.dismissAccessPinSuccess()

            XCTAssertFalse(f.presenter.showAccessPinSuccessPopup)
            XCTAssertEqual(Router.shared.path.count, 2)
            XCTAssertEqual(Router.shared.currentRoute, .privacyPolicy)
            XCTAssertEqual(AuthSessionManager.uploadQueueSession?.ownerUserId, "pin-owner-b")
            XCTAssertEqual(f.presenter.user.id, "pin-owner-b")
            XCTAssertEqual(KeychainHelper.string(for: .accessPin), "9753")
            XCTAssertEqual(KeychainHelper.string(for: .accessToken), "pin-owner-b-access")
        }
    }

    @MainActor
    func testCreateRequiresASecondMatchingPINBeforeSendingMutation() async throws {
        for confirmation in ["", "9999"] {
            try await withFixture { f in
                KeychainHelper.remove(.accessPin)
                f.presenter.firstPin = "1357"
                f.presenter.secondPin = confirmation
                _ = await f.presenter.createAccessPin()
                XCTAssertTrue(f.presenter.isError)
                XCTAssertNil(KeychainHelper.string(for: .accessPin))
                XCTAssertTrue(f.network.requests.isEmpty)
                XCTAssertFalse(f.presenter.isPinAuthorized)
                XCTAssertFalse(UserDefaults.standard.bool(forKey: UserDefaultType.firstTimeLogin.rawValue))
            }
        }
    }

    @MainActor
    func testConfirmedCreateCompletesOnboardingOnlyAfterServerSuccess() async throws {
        try await withFixture { f in
            KeychainHelper.remove(.accessPin)
            f.presenter.state = .revalidate
            f.presenter.firstPin = "1357"
            f.appState.initializationState = .requiresPinCreation

            await f.presenter.handlePinInput("1357")

            XCTAssertFalse(f.presenter.isError)
            XCTAssertEqual(KeychainHelper.string(for: .accessPin), "1357")
            XCTAssertTrue(UserDefaults.standard.bool(forKey: UserDefaultType.firstTimeLogin.rawValue))
            XCTAssertEqual(f.appState.initializationState, .createFaceId)
            XCTAssertEqual(f.network.requests.filter { $0.method == "POST" }.count, 1)
        }
    }

    @MainActor
    func testDuplicateCreateInputCannotCompleteOnboardingBeforeHeldRequestIsAccepted() async throws {
        try await withFixture { f in
            KeychainHelper.remove(.accessPin)
            f.presenter.state = .revalidate
            f.presenter.firstPin = "1357"
            f.appState.initializationState = .requiresPinCreation
            f.presenter.inputPin = "1357"
            let started = expectation(description: "First PIN creation held at server")
            let gate = AccountMutationGate()
            f.network.response = { _ in
                started.fulfill()
                await gate.wait()
                return try AccountMutationFixture.mutationPayload(hasPin: true)
            }
            let first = Task { await f.presenter.handlePinInput("1357") }
            await fulfillment(of: [started], timeout: 2)
            XCTAssertTrue(f.presenter.isLoading)
            XCTAssertNil(KeychainHelper.string(for: .accessPin))
            XCTAssertFalse(UserDefaults.standard.bool(forKey: UserDefaultType.firstTimeLogin.rawValue))

            let duplicateReturned = expectation(description: "Duplicate input is ignored while creation is pending")
            let duplicate = Task {
                await f.presenter.handlePinInput("1357")
                duplicateReturned.fulfill()
            }
            await fulfillment(of: [duplicateReturned], timeout: 2)
            XCTAssertEqual(f.presenter.inputPin, "1357", "Ignoring a duplicate must not clear input and cancel the pending view task")
            XCTAssertEqual(f.network.requests.filter { $0.method == "POST" }.count, 1)
            XCTAssertTrue(f.presenter.isLoading)
            XCTAssertNil(KeychainHelper.string(for: .accessPin))
            XCTAssertFalse(UserDefaults.standard.bool(forKey: UserDefaultType.firstTimeLogin.rawValue))
            XCTAssertEqual(f.appState.initializationState, .requiresPinCreation)

            await gate.open()
            await first.value
            await duplicate.value
            XCTAssertEqual(f.network.requests.filter { $0.method == "POST" }.count, 1)
            XCTAssertEqual(KeychainHelper.string(for: .accessPin), "1357")
            XCTAssertTrue(UserDefaults.standard.bool(forKey: UserDefaultType.firstTimeLogin.rawValue))
            XCTAssertEqual(f.appState.initializationState, .createFaceId)
            XCTAssertFalse(f.presenter.isLoading)
            XCTAssertFalse(f.presenter.isError)
        }
    }

    @MainActor
    func testFailedCreateNeverCachesPINOrClaimsConfirmation() async throws {
        try await withFixture { f in
            KeychainHelper.remove(.accessPin)
            f.presenter.firstPin = "1357"
            f.presenter.secondPin = "1357"
            f.network.response = { _ in throw URLError(.networkConnectionLost) }
            _ = await f.presenter.createAccessPin()
            XCTAssertTrue(f.presenter.isError)
            XCTAssertNil(KeychainHelper.string(for: .accessPin))
            XCTAssertFalse(f.presenter.isPinAuthorized)
            XCTAssertFalse(f.presenter.showAccessPinSuccessPopup)
            XCTAssertFalse(UserDefaults.standard.bool(forKey: UserDefaultType.firstTimeLogin.rawValue))
        }
    }

    @MainActor
    func testServerExistingPINOnFreshDeviceRequiresAuthenticationWithoutInventingCachedPIN() async throws {
        try await withFixture { f in
            KeychainHelper.remove(.accessPin)
            f.network.response = { _ in try AccountMutationFixture.userPayload(hasPin: true) }

            await f.presenter.getAccountById()

            XCTAssertTrue(f.presenter.user.hasAccessPin)
            if case .authenticate = f.presenter.state {} else { XCTFail("Server PIN presence must not route to PIN creation") }
            XCTAssertEqual(f.appState.initializationState, .requiresPinAuthentication)
            XCTAssertNil(f.presenter.user.accessPin)
            XCTAssertNil(KeychainHelper.string(for: .accessPin))
            XCTAssertFalse(f.presenter.isPinAuthorized)

            f.presenter.inputPin = "1357"
            await f.presenter.handlePinInput("1357")
            XCTAssertTrue(f.presenter.isError)
            XCTAssertFalse(f.presenter.isPinAuthorized)
            XCTAssertNil(KeychainHelper.string(for: .accessPin))
            XCTAssertEqual(f.network.requests.filter { $0.method != "GET" }.count, 0)
            XCTAssertFalse(UserDefaults.standard.bool(forKey: UserDefaultType.firstTimeLogin.rawValue))
        }
    }

    @MainActor
    func testServerWithoutPINAndNoCacheAllowsPINCreation() async throws {
        try await withFixture { f in
            KeychainHelper.remove(.accessPin)
            f.network.response = { _ in try AccountMutationFixture.userPayload(hasPin: false) }
            await f.presenter.getAccountById()
            XCTAssertFalse(f.presenter.user.hasAccessPin)
            if case .create = f.presenter.state {} else { XCTFail("An account without a server or cached PIN needs creation") }
            XCTAssertEqual(f.appState.initializationState, .requiresPinCreation)
            XCTAssertNil(KeychainHelper.string(for: .accessPin))
            XCTAssertFalse(f.presenter.isPinAuthorized)
        }
    }
}

private enum AccountPINMutation: String, CaseIterable {
    case create, update, delete

    @MainActor
    func perform(using interactor: AuthenticationInteractor) async throws {
        switch self {
        case .create: _ = try await interactor.createAccessPin(accessPin: "1357")
        case .update: _ = try await interactor.editNewPIN(newAccessPin: "8642", previousAccessPin: "2468")
        case .delete: _ = try await interactor.deleteAccessPin()
        }
    }

    @MainActor
    func perform(using presenter: AuthenticationPresenter) async {
        switch self {
        case .create: await presenter.handlePinInput("1357")
        case .update: await presenter.editAccessPin()
        case .delete: await presenter.handleForgetPin()
        }
    }
}

@MainActor
private final class AccountMutationFixture {
    let context: ModelContext
    let network = AccountMutationNetwork()
    let interactor: AuthenticationInteractor
    let presenter: AuthenticationPresenter
    let appState = AppStateManager()

    init() throws {
        let schema = Schema([User.self, PendingUpload.self])
        context = ModelContext(try ModelContainer(
            for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        ))
        interactor = AuthenticationInteractor(modelContext: context, networkService: network)
        presenter = AuthenticationPresenter(interactor: interactor)
        presenter.appStateManager = appState
        presenter.user = insertUser(owner: "pin-owner-a", name: "First account")
        network.response = { request in
            if request.path.contains("/get-user-data-by-id/") || request.path.contains("/update-user/") {
                return try Self.userPayload(hasPin: true)
            }
            return try Self.mutationPayload(hasPin: request.method != "DELETE")
        }
    }

    @discardableResult
    func insertUser(owner: String, name: String) -> User {
        let user = User(id: owner, name: name, role: .LAB, businessModel: .B2C)
        context.insert(user)
        do { try context.save() } catch { XCTFail("Could not save isolated account fixture: \(error)") }
        return user
    }

    func replaceSession(logout: Bool) async throws {
        if logout {
            await presenter.performLogout()
        } else {
            Self.setSession(owner: "pin-owner-b", pin: "9753")
            for user in try context.fetch(FetchDescriptor<User>()) { context.delete(user) }
            presenter.user = insertUser(owner: "pin-owner-b", name: "Current second account")
        }
    }

    static func setSession(owner: String, pin: String?) {
        AuthSessionManager.beginSessionChange()
        XCTAssertTrue(KeychainHelper.set("\(owner)-access", for: .accessToken))
        XCTAssertTrue(KeychainHelper.set("\(owner)-refresh", for: .refreshToken))
        if let pin { XCTAssertTrue(KeychainHelper.set(pin, for: .accessPin)) }
        else { KeychainHelper.remove(.accessPin) }
        UserDefaults.standard.set(owner, forKey: UserDefaultType.userId.rawValue)
        UserDefaults.standard.set(true, forKey: UserDefaultType.isUserLoggedIn.rawValue)
        UserDefaults.standard.set(false, forKey: UserDefaultType.isPinSessionAuthorized.rawValue)
        AuthSessionManager.completeSessionChange()
    }

    static func userPayload(name: String = "Server account", hasPin: Bool) throws -> Data {
        try payload([
            "id": "pin-owner-a", "name": name, "role": "LAB", "email": "user@example.invalid",
            "businessModel": "B2C", "emailVerified": true, "hasAccessPin": hasPin
        ])
    }

    static func mutationPayload(hasPin: Bool) throws -> Data {
        // Actual safe BE shape: confirmation metadata, never plaintext PIN/hash.
        try payload(["userId": "pin-owner-a", "email": "user@example.invalid", "hasAccessPin": hasPin])
    }

    private static func payload(_ data: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: [
            "status": "success", "code": 200, "message": "Confirmed", "data": data
        ])
    }
}

private struct AccountMutationRequest {
    let method: String
    let url: String
    let headers: [String: String]?
    let body: Data?
    var path: String { URL(string: url)?.path ?? url }
}

private final class AccountMutationNetwork: MockNetworkService {
    var response: (@MainActor (AccountMutationRequest) async throws -> Data)!
    @MainActor private(set) var requests: [AccountMutationRequest] = []

    private func perform<T: Decodable>(_ request: AccountMutationRequest) async throws -> APIResponse<T> {
        await MainActor.run { requests.append(request) }
        return try JSONDecoder().decode(APIResponse<T>.self, from: await response(request))
    }

    override func get<T: Decodable>(urlString: String, headers: [String: String]?) async throws -> APIResponse<T> {
        try await perform(AccountMutationRequest(method: "GET", url: urlString, headers: headers, body: nil))
    }

    override func post<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B) async throws -> APIResponse<T> {
        try await perform(AccountMutationRequest(method: "POST", url: urlString, headers: headers, body: JSONEncoder().encode(body)))
    }

    override func update<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B) async throws -> APIResponse<T> {
        try await perform(AccountMutationRequest(method: "PUT", url: urlString, headers: headers, body: JSONEncoder().encode(body)))
    }

    override func delete<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B?) async throws -> APIResponse<T> {
        let data = try body.map { try JSONEncoder().encode($0) }
        return try await perform(AccountMutationRequest(method: "DELETE", url: urlString, headers: headers, body: data))
    }
}

private actor AccountMutationGate {
    private var continuations: [CheckedContinuation<Void, Never>] = []
    private var isOpen = false
    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { continuations.append($0) }
    }
    func open() {
        isOpen = true
        let pending = continuations
        continuations.removeAll()
        for continuation in pending { continuation.resume() }
    }
}
