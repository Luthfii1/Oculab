import SwiftData
import SwiftUI
import Combine
import XCTest
@testable import Oculab

final class ProfilePasswordTests: XCTestCase {
    @MainActor
    private func withFixture(_ body: (PasswordFixture) async throws -> Void) async throws {
        let keys: [KeychainKey] = [.accessToken, .refreshToken, .accessPin]
        let secrets = keys.map { ($0, KeychainHelper.string(for: $0)) }
        let defaults = UserDefaultType.allCases.map { ($0, UserDefaults.standard.object(forKey: $0.rawValue)) }
        let path = Router.shared.path
        let route = Router.shared.currentRoute
        defer {
            AuthSessionManager.beginSessionChange()
            for (key, value) in secrets {
                if let value { KeychainHelper.set(value, for: key) }
                else { KeychainHelper.remove(key) }
            }
            for (key, value) in defaults { UserDefaults.standard.set(value, forKey: key.rawValue) }
            AuthSessionManager.completeSessionChange()
            Router.shared.path = path
            Router.shared.currentRoute = route
        }
        PasswordFixture.setSession("password-owner-a")
        try await body(PasswordFixture())
    }

    @MainActor
    func testSafeBackend200DecodesWithoutPasswordAndUsesExpectedRequest() async throws {
        try await withFixture { f in
            let response = try await f.interactor.editNewPassword(newPassword: "NewPassword2!", previousPassword: "OldPassword1!")
            XCTAssertEqual(response.userId, "password-owner-a")
            XCTAssertEqual(response.email, "user@example.invalid")
            XCTAssertEqual(f.network.lastURL, API.BE + "/user/update-user-password/password-owner-a")
            XCTAssertEqual(f.network.lastHeaders?["Authorization"], "Bearer password-owner-a-access")
            XCTAssertEqual(f.network.lastBody, ["previousPassword": "OldPassword1!", "newPassword": "NewPassword2!"])
            let encoded = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(response)) as? [String: String])
            XCTAssertNil(encoded["newPassword"], "A successful password response must never require or retain the secret")
            XCTAssertEqual(Set(encoded.keys), ["userId", "email"])
        }
    }

    @MainActor
    func testSuccessfulPasswordChangeShowsSuccessAndClearsSecretFields() async throws {
        try await withFixture { f in
            f.fillPasswordForm()
            await f.presenter.postEditPasswordWithValidation(authPresenter: f.authPresenter)
            XCTAssertEqual(f.network.updateCount, 1)
            XCTAssertTrue(f.presenter.showSuccessPopup)
            XCTAssertFalse(f.presenter.isLoading)
            XCTAssertTrue(f.presenter.oldPassword.isEmpty)
            XCTAssertTrue(f.presenter.inputPassword.isEmpty)
            XCTAssertTrue(f.presenter.confirmPassword.isEmpty)
            XCTAssertTrue(f.presenter.generalFormError.isEmpty)
            XCTAssertEqual(KeychainHelper.string(for: .accessToken), "password-owner-a-access")
        }
    }

    @MainActor
    func testDuplicateSubmissionsSendOnlyOnePasswordMutation() async throws {
        try await withFixture { f in
            f.fillPasswordForm()
            let started = expectation(description: "First password request started")
            let gate = PasswordGate()
            f.network.response = { _, _, _ in
                started.fulfill()
                await gate.wait()
                return PasswordFixture.safeResponse()
            }
            let request = Task { await f.presenter.postEditPasswordWithValidation(authPresenter: f.authPresenter) }
            await fulfillment(of: [started], timeout: 2)
            XCTAssertTrue(f.presenter.isLoading)
            await f.presenter.postEditPasswordWithValidation(authPresenter: f.authPresenter)
            await f.presenter.postEditPassword(authPresenter: f.authPresenter)
            XCTAssertEqual(f.network.updateCount, 1)
            await gate.open()
            await request.value
            XCTAssertTrue(f.presenter.showSuccessPopup)
            XCTAssertFalse(f.presenter.isLoading)
        }
    }

    @MainActor
    func testIncorrectCurrentPasswordMapsToFieldErrorAndPreservesInputs() async throws {
        try await withFixture { f in
            f.fillPasswordForm()
            f.network.response = { _, _, _ in
                throw NetworkError.apiError(APIResponse(
                    status: "error", code: 400, message: "Invalid previous password",
                    data: ApiErrorData(errorType: "VALIDATION_ERROR", description: "The previous password provided is incorrect.")
                ))
            }
            await f.presenter.postEditPasswordWithValidation(authPresenter: f.authPresenter)
            XCTAssertEqual(f.network.updateCount, 1)
            XCTAssertFalse(f.presenter.showSuccessPopup)
            XCTAssertFalse(f.presenter.isLoading)
            XCTAssertEqual(f.presenter.oldPassword, "OldPassword1!")
            XCTAssertEqual(f.presenter.inputPassword, "NewPassword2!")
            XCTAssertEqual(ValidationManager.shared.getError(for: ValidationFieldName.currentPassword.fieldName),
                           AppTextAuthEditPassword.currentPasswordIncorrect)
            XCTAssertEqual(f.presenter.formValidation.getError(for: .currentPassword),
                           AppTextAuthEditPassword.currentPasswordIncorrect)
        }
    }

    @MainActor
    func testPasswordErrorResetCannotLeakQueuedErrorIntoNewSessionForm() async throws {
        try await withFixture { f in
            f.fillPasswordForm()
            f.network.response = { _, _, _ in
                throw NetworkError.apiError(APIResponse(
                    status: "error", code: 400, message: "Invalid previous password",
                    data: ApiErrorData(errorType: "VALIDATION_ERROR", description: "The previous password provided is incorrect.")
                ))
            }
            await f.presenter.postEditPasswordWithValidation(authPresenter: f.authPresenter)
            XCTAssertEqual(f.presenter.formValidation.getError(for: .currentPassword), AppTextAuthEditPassword.currentPasswordIncorrect)
            PasswordFixture.setSession("password-owner-b")
            XCTAssertNil(f.presenter.formValidation.getError(for: .currentPassword), "Session reset must clear A's error immediately")
            f.presenter.preparePasswordEditForm()
            ValidationManager.shared.setError("B form error", for: ValidationFieldName.newPassword.fieldName)
            XCTAssertEqual(f.presenter.formValidation.getError(for: .newPassword), "B form error")
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                DispatchQueue.main.async { continuation.resume() }
            }
            XCTAssertNil(f.presenter.formValidation.getError(for: .currentPassword))
            XCTAssertEqual(f.presenter.formValidation.getError(for: .newPassword), "B form error",
                           "An old queued clear must not erase the new form's error")
        }
    }

    @MainActor
    func testValidationErrorHelpersMutateImmediatelyOnMainThread() async {
        let manager = ValidationManager()
        manager.setError("First", for: "first")
        manager.setError("Second", for: "second")
        XCTAssertEqual(manager.getError(for: "first"), "First")
        manager.clearError(for: "first")
        XCTAssertNil(manager.getError(for: "first"))
        XCTAssertEqual(manager.getError(for: "second"), "Second")
        manager.clearAllErrors()
        XCTAssertTrue(manager.errors.isEmpty)
        manager.setError("New form", for: "new")
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async { continuation.resume() }
        }
        XCTAssertEqual(manager.errors, ["new": "New form"])
    }

    @MainActor
    func testBackgroundValidationHelpersStillPublishInOrderOnMainThread() async {
        let manager = ValidationManager()
        let delivered = expectation(description: "Four background edits delivered on main")
        delivered.expectedFulfillmentCount = 4
        let observer = manager.$errors.dropFirst().sink { _ in
            XCTAssertTrue(Thread.isMainThread)
            delivered.fulfill()
        }
        await Task.detached {
            manager.setError("Background", for: "first")
            manager.clearError(for: "first")
            manager.setError("Second", for: "second")
            manager.clearAllErrors()
        }.value
        await fulfillment(of: [delivered], timeout: 2)
        XCTAssertTrue(manager.errors.isEmpty)
        withExtendedLifetime(observer) {}
    }

    @MainActor
    func testNetworkFailureDoesNotClaimPasswordWasChanged() async throws {
        try await withFixture { f in
            f.fillPasswordForm()
            f.network.response = { _, _, _ in throw URLError(.networkConnectionLost) }
            await f.presenter.postEditPasswordWithValidation(authPresenter: f.authPresenter)
            XCTAssertFalse(f.presenter.showSuccessPopup)
            XCTAssertFalse(f.presenter.generalFormError.isEmpty)
            XCTAssertEqual(f.presenter.oldPassword, "OldPassword1!")
            XCTAssertEqual(f.presenter.confirmPassword, "NewPassword2!")
            XCTAssertFalse(f.presenter.isLoading)
        }
    }

    @MainActor
    func testInteractorRejectsOldResponseAfterAccountSwitchOrLogout() async throws {
        for logout in [false, true] {
            try await withFixture { f in
                let started = expectation(description: "Interactor password request held")
                let gate = PasswordGate()
                f.network.response = { _, _, _ in
                    started.fulfill()
                    await gate.wait()
                    return PasswordFixture.safeResponse()
                }
                let request = Task { try await f.interactor.editNewPassword(newPassword: "NewPassword2!", previousPassword: "OldPassword1!") }
                await fulfillment(of: [started], timeout: 2)
                if logout { AuthSessionManager.invalidateSession() }
                else { PasswordFixture.setSession("password-owner-b") }
                await gate.open()
                do {
                    _ = try await request.value
                    XCTFail("Old account responses must not be accepted in a new session")
                } catch is CancellationError {}
                XCTAssertEqual(KeychainHelper.string(for: .accessToken), logout ? nil : "password-owner-b-access")
            }
        }
    }

    @MainActor
    func testInteractorRejectsSuccessfulResponseForDifferentUser() async throws {
        try await withFixture { f in
            f.network.response = { _, _, _ in PasswordFixture.safeResponse(owner: "different-owner") }
            do {
                _ = try await f.interactor.editNewPassword(newPassword: "NewPassword2!", previousPassword: "OldPassword1!")
                XCTFail("A response for another user cannot authorize a success popup")
            } catch is CancellationError {}
        }
    }

    @MainActor
    func testPresenterDiscardsStaleSuccessAndErrorEvenFromUnguardedInteractor() async throws {
        for failed in [false, true] {
            try await withFixture { f in
                let started = expectation(description: "Presenter password request held")
                let gate = PasswordGate()
                let stub = DelayedPasswordInteractor {
                    started.fulfill()
                    await gate.wait()
                    if failed { throw URLError(.timedOut) }
                    return UserUpdatePasswordResponse(userId: "password-owner-a", email: "user@example.invalid")
                }
                let presenter = ProfilePresenter(interactor: stub, authInteractor: f.authInteractor)
                presenter.oldPassword = "OldPassword1!"
                presenter.inputPassword = "NewPassword2!"
                presenter.confirmPassword = "NewPassword2!"
                let request = Task { await presenter.postEditPasswordWithValidation(authPresenter: f.authPresenter) }
                await fulfillment(of: [started], timeout: 2)
                PasswordFixture.setSession("password-owner-b")
                presenter.oldPassword = "B-old-password"
                presenter.inputPassword = "B-new-password"
                presenter.confirmPassword = "B-new-password"
                Router.shared.path.append(Router.Route.profile)
                Router.shared.currentRoute = .profile
                let bPathCount = Router.shared.path.count
                await gate.open()
                await request.value
                XCTAssertFalse(presenter.showSuccessPopup)
                XCTAssertTrue(presenter.generalFormError.isEmpty)
                XCTAssertFalse(presenter.isLoading)
                XCTAssertEqual(presenter.oldPassword, "B-old-password")
                XCTAssertEqual(presenter.inputPassword, "B-new-password")
                XCTAssertEqual(Router.shared.path.count, bPathCount)
                XCTAssertEqual(Router.shared.currentRoute, .profile)
            }
        }
    }

    @MainActor
    func testOldSuccessPopupCannotPopNewSessionsNavigation() async throws {
        try await withFixture { f in
            f.fillPasswordForm()
            await f.presenter.postEditPasswordWithValidation(authPresenter: f.authPresenter)
            XCTAssertTrue(f.presenter.showSuccessPopup)
            PasswordFixture.setSession("password-owner-b")
            Router.shared.path.append(Router.Route.editPassword)
            Router.shared.currentRoute = .editPassword
            let count = Router.shared.path.count
            f.presenter.backToProfilePage()
            XCTAssertFalse(f.presenter.showSuccessPopup)
            XCTAssertEqual(Router.shared.path.count, count)
            XCTAssertEqual(Router.shared.currentRoute, .editPassword)
        }
    }

    @MainActor
    func testCurrentSuccessPopupReturnsToRootSynchronously() async throws {
        try await withFixture { f in
            f.fillPasswordForm()
            await f.presenter.postEditPasswordWithValidation(authPresenter: f.authPresenter)
            Router.shared.path.append(Router.Route.editPassword)
            Router.shared.currentRoute = .editPassword
            f.presenter.backToProfilePage()
            XCTAssertTrue(Router.shared.path.isEmpty)
            XCTAssertNil(Router.shared.currentRoute)
            XCTAssertFalse(f.presenter.showSuccessPopup)
        }
    }

    @MainActor
    func testResetFormInvalidatesInFlightRequestWithoutSuccessOrError() async throws {
        try await withFixture { f in
            f.fillPasswordForm()
            let started = expectation(description: "Password request held until form resets")
            let gate = PasswordGate()
            f.network.response = { _, _, _ in
                started.fulfill()
                await gate.wait()
                return PasswordFixture.safeResponse()
            }
            let request = Task { await f.presenter.postEditPasswordWithValidation(authPresenter: f.authPresenter) }
            await fulfillment(of: [started], timeout: 2)
            f.presenter.resetEditPassword()
            await gate.open()
            await request.value
            XCTAssertFalse(f.presenter.showSuccessPopup)
            XCTAssertFalse(f.presenter.isLoading)
            XCTAssertTrue(f.presenter.generalFormError.isEmpty)
            XCTAssertTrue(f.presenter.oldPassword.isEmpty)
        }
    }
}

@MainActor
private final class PasswordFixture {
    let network = PasswordNetwork()
    let context: ModelContext
    let interactor: ProfileInteractor
    let authInteractor: AuthenticationInteractor
    let authPresenter: AuthenticationPresenter
    let presenter: ProfilePresenter

    init() throws {
        let schema = Schema([User.self])
        context = ModelContext(try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]))
        authInteractor = AuthenticationInteractor(modelContext: context, networkService: MockNetworkService())
        authPresenter = AuthenticationPresenter(interactor: authInteractor)
        interactor = ProfileInteractor(networkService: network)
        presenter = ProfilePresenter(interactor: interactor, authInteractor: authInteractor)
        network.response = { _, _, _ in Self.safeResponse() }
    }

    func fillPasswordForm() {
        presenter.preparePasswordEditForm()
        presenter.oldPassword = "OldPassword1!"
        presenter.inputPassword = "NewPassword2!"
        presenter.confirmPassword = "NewPassword2!"
    }

    static func setSession(_ owner: String) {
        AuthSessionManager.beginSessionChange()
        KeychainHelper.set("\(owner)-access", for: .accessToken)
        KeychainHelper.set("\(owner)-refresh", for: .refreshToken)
        UserDefaults.standard.set(owner, forKey: UserDefaultType.userId.rawValue)
        UserDefaults.standard.set(true, forKey: UserDefaultType.isUserLoggedIn.rawValue)
        AuthSessionManager.completeSessionChange()
    }

    static func safeResponse(owner: String = "password-owner-a") -> Data {
        Data("{\"status\":\"success\",\"code\":200,\"message\":\"User's password updated successfully\",\"data\":{\"userId\":\"\(owner)\",\"email\":\"user@example.invalid\"}}".utf8)
    }
}

private final class PasswordNetwork: MockNetworkService {
    var response: (@MainActor (String, [String: String]?, Data) async throws -> Data)!
    @MainActor private(set) var updateCount = 0
    @MainActor private(set) var lastURL: String?
    @MainActor private(set) var lastHeaders: [String: String]?
    @MainActor private(set) var lastBody: [String: String]?

    override func update<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B) async throws -> APIResponse<T> {
        let data = try JSONEncoder().encode(body)
        await MainActor.run {
            updateCount += 1
            lastURL = urlString
            lastHeaders = headers
            lastBody = (try? JSONSerialization.jsonObject(with: data)) as? [String: String]
        }
        let responseData = try await response(urlString, headers, data)
        return try JSONDecoder().decode(APIResponse<T>.self, from: responseData)
    }
}

private final class DelayedPasswordInteractor: ProfileInteractorProtocol {
    let action: @MainActor () async throws -> UserUpdatePasswordResponse
    init(action: @escaping @MainActor () async throws -> UserUpdatePasswordResponse) { self.action = action }
    func editNewPassword(newPassword: String, previousPassword: String) async throws -> UserUpdatePasswordResponse { try await action() }
    func activateFaceID() async throws {}
}

private actor PasswordGate {
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
