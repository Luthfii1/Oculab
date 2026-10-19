@testable import Oculab
import Alamofire
import SwiftData
import XCTest

final class NetworkRetryManagerTests: XCTestCase {
    @MainActor
    func testDuplicateIsRejectedDuringFirstAttempt() async throws {
        let manager = NetworkRetryManager()
        let started = expectation(description: "First request started")
        let release = AsyncGate()
        let first = Task {
            try await manager.executeWithRetry(id: "same-request") {
                started.fulfill()
                await release.wait()
                return 42
            }
        }
        await fulfillment(of: [started], timeout: 2)
        do {
            _ = try await manager.executeWithRetry(id: "same-request") { 0 }
            XCTFail("Duplicate request should be rejected during the first attempt")
        } catch NetworkError.networkError(let message, _) {
            XCTAssertEqual(message, "Operation already in progress")
        }
        await release.open()
        let value = try await first.value
        XCTAssertEqual(value, 42)
        let next = try await manager.executeWithRetry(id: "same-request") { 7 }
        XCTAssertEqual(next, 7)
    }

    @MainActor
    func testCancellationDuringBackoffReleasesOperationID() async throws {
        let manager = NetworkRetryManager()
        let attempted = expectation(description: "Attempt failed")
        let task = Task {
            try await manager.executeWithRetry(id: "cancel-backoff") { () -> Int in
                attempted.fulfill()
                throw URLError(.timedOut)
            }
        }
        await fulfillment(of: [attempted], timeout: 2)
        // Backoff is at least 1.1 seconds; cancellation must release the ID.
        try await Task.sleep(nanoseconds: 100_000_000)
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {}
        let value = try await manager.executeWithRetry(id: "cancel-backoff") { 9 }
        XCTAssertEqual(value, 9)
    }

    @MainActor
    func testCancellationErrorsAreNotRetried() async throws {
        let manager = NetworkRetryManager()
        let calls = RequestLog()
        do {
            _ = try await manager.executeWithRetry(id: "cancel-error") { () -> Int in
                calls.append("attempt")
                throw CancellationError()
            }
            XCTFail("Expected cancellation")
        } catch is CancellationError {}
        XCTAssertEqual(calls.values.count, 1)
    }

    @MainActor
    func testCancelledURLRequestsAreNotRetried() async throws {
        let manager = NetworkRetryManager()
        let calls = RequestLog()
        do {
            _ = try await manager.executeWithRetry(id: "cancel-url") { () -> Int in
                calls.append("attempt")
                throw URLError(.cancelled)
            }
            XCTFail("Expected cancellation")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .cancelled)
        }
        XCTAssertEqual(calls.values.count, 1)
    }

    @MainActor
    func testInvalidAttemptCountDoesNotRunOperation() async {
        let manager = NetworkRetryManager()
        for count in [0, -1] {
            do {
                _ = try await manager.executeWithRetry(id: "invalid", maxAttempts: count) {
                    XCTFail("Invalid attempt count must not execute the operation")
                    return 0
                }
                XCTFail("Expected invalid attempt count to throw")
            } catch {}
        }
    }

    @MainActor
    func testTransientFailureRetriesThenSucceeds() async throws {
        let manager = NetworkRetryManager()
        let calls = RequestLog()
        let result = try await manager.executeWithRetry(id: "transient", maxAttempts: 2) {
            calls.append("attempt")
            if calls.values.count == 1 { throw URLError(.timedOut) }
            return 23
        }
        XCTAssertEqual(result, 23)
        XCTAssertEqual(calls.values.count, 2)
    }
}

final class AlamofireNetworkServiceTests: XCTestCase {
    private var service: AlamofireNetworkService!
    private var session: Session!
    private var savedTokens: [KeychainKey: String] = [:]
    private var savedDefaults: [String: Any] = [:]
    private let authKeys: [UserDefaultType] = [.userId, .isUserLoggedIn, .isPinSessionAuthorized]
    private let endpoint = API.BE + "/review-test"

    override func setUpWithError() throws {
        for key in [KeychainKey.accessToken, .refreshToken, .accessPin] {
            savedTokens[key] = KeychainHelper.string(for: key)
        }
        for key in authKeys {
            savedDefaults[key.rawValue] = UserDefaults.standard.object(forKey: key.rawValue)
        }
        XCTAssertTrue(KeychainHelper.set("old-access", for: .accessToken))
        XCTAssertTrue(KeychainHelper.set("old-refresh", for: .refreshToken))
        UserDefaults.standard.set("review-user", forKey: UserDefaultType.userId.rawValue)
        UserDefaults.standard.set(true, forKey: UserDefaultType.isUserLoggedIn.rawValue)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        session = Session(configuration: configuration)
        service = AlamofireNetworkService(session: session)
    }

    override func tearDownWithError() throws {
        session.session.invalidateAndCancel()
        service = nil
        session = nil
        StubURLProtocol.handler = nil
        for key in [KeychainKey.accessToken, .refreshToken, .accessPin] {
            if let value = savedTokens[key] {
                KeychainHelper.set(value, for: key)
            } else {
                KeychainHelper.remove(key)
            }
        }
        for key in authKeys {
            if let value = savedDefaults[key.rawValue] {
                UserDefaults.standard.set(value, forKey: key.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: key.rawValue)
            }
        }
    }

    func testRefreshTimeoutPreservesSessionAndOriginalError() async throws {
        StubURLProtocol.handler = { request in
            if request.url!.path.contains("refresh-token") { throw URLError(.timedOut) }
            return (401, "{}")
        }
        do {
            let _: APIResponse<EmptyPayload> = try await service.get(urlString: endpoint, headers: nil)
            XCTFail("Expected timeout")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .timedOut)
        }
        XCTAssertEqual(KeychainHelper.string(for: .accessToken), "old-access")
        XCTAssertEqual(KeychainHelper.string(for: .refreshToken), "old-refresh")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: UserDefaultType.isUserLoggedIn.rawValue))
    }

    func testSuccessfulRefreshRetriesRequestWithNewToken() async throws {
        StubURLProtocol.handler = { request in
            if request.url!.path.contains("refresh-token") { return (200, Self.refreshResponse) }
            if request.value(forHTTPHeaderField: "Authorization") == "Bearer new-access" {
                return (200, #"{"status":"success","code":200,"message":"OK","data":{"value":42}}"#)
            }
            return (401, "{}")
        }
        let response: APIResponse<ValuePayload> = try await service.get(urlString: endpoint, headers: nil)
        XCTAssertEqual(response.data.value, 42)
        XCTAssertEqual(KeychainHelper.string(for: .accessToken), "new-access")
        XCTAssertEqual(KeychainHelper.string(for: .refreshToken), "new-refresh")
    }

    func testAPIErrorAfterRefreshDoesNotLogOut() async throws {
        let calls = RequestLog()
        StubURLProtocol.handler = { request in
            let authorization = request.value(forHTTPHeaderField: "Authorization") ?? ""
            calls.append(authorization)
            if request.url!.path.contains("refresh-token") { return (200, Self.refreshResponse) }
            if authorization == "Bearer new-access" { return (403, Self.permissionError) }
            return (401, "{}")
        }
        do {
            let _: APIResponse<EmptyPayload> = try await service.get(urlString: endpoint, headers: nil)
            XCTFail("Expected permission error")
        } catch NetworkError.apiError(let response, _) {
            XCTAssertEqual(response.data.errorType, "PERMISSION_ERROR")
        }
        XCTAssertEqual(calls.values, ["Bearer old-access", "Bearer old-refresh", "Bearer new-access"])
        XCTAssertEqual(KeychainHelper.string(for: .accessToken), "new-access")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: UserDefaultType.isUserLoggedIn.rawValue))
    }

    func testRejectedRefreshInvalidatesSessionOnce() async throws {
        let notifications = RequestLog()
        let observer = NotificationCenter.default.addObserver(
            forName: AuthSessionManager.sessionDidInvalidateNotification, object: nil, queue: nil
        ) { _ in notifications.append("invalidated") }
        defer { NotificationCenter.default.removeObserver(observer) }
        StubURLProtocol.handler = { _ in (401, "{}") }
        do {
            let _: APIResponse<EmptyPayload> = try await service.get(urlString: endpoint, headers: nil)
            XCTFail("Expected unauthorized")
        } catch NetworkError.unauthorized {}
        XCTAssertNil(KeychainHelper.string(for: .accessToken))
        XCTAssertNil(KeychainHelper.string(for: .refreshToken))
        XCTAssertFalse(UserDefaults.standard.bool(forKey: UserDefaultType.isUserLoggedIn.rawValue))
        XCTAssertEqual(notifications.values.count, 1)
    }

    func testUnauthorizedAfterSuccessfulRefreshInvalidatesSession() async throws {
        StubURLProtocol.handler = { request in
            if request.url!.path.contains("refresh-token") { return (200, Self.refreshResponse) }
            return (401, "{}")
        }
        do {
            let _: APIResponse<EmptyPayload> = try await service.get(urlString: endpoint, headers: nil)
            XCTFail("Expected unauthorized")
        } catch NetworkError.unauthorized {}
        XCTAssertNil(KeychainHelper.string(for: .accessToken))
        XCTAssertFalse(UserDefaults.standard.bool(forKey: UserDefaultType.isUserLoggedIn.rawValue))
    }

    func testRejectedLoginDoesNotInvalidateExistingSession() async throws {
        StubURLProtocol.handler = { _ in (401, "{}") }
        do {
            let _: APIResponse<EmptyPayload> = try await service.post(
                urlString: API.BE + "/user/login", headers: nil, body: ["email": "test@example.invalid"]
            )
            XCTFail("Expected unauthorized")
        } catch NetworkError.unauthorized {}
        XCTAssertEqual(KeychainHelper.string(for: .accessToken), "old-access")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: UserDefaultType.isUserLoggedIn.rawValue))
    }

    func testErrorEnvelopeCannotBeReturnedAsSuccess() async throws {
        StubURLProtocol.handler = { _ in
            (200, #"{"status":"error","code":400,"message":"Invalid request","data":{}}"#)
        }
        do {
            let _: APIResponse<EmptyPayload> = try await service.get(urlString: endpoint, headers: nil)
            XCTFail("An error envelope must throw even when its data decodes")
        } catch NetworkError.networkError(let message, _) {
            XCTAssertEqual(message, "Invalid request")
        }
    }

    func testHTTPFailureCannotBeReturnedAsSuccess() async throws {
        StubURLProtocol.handler = { _ in
            (403, #"{"status":"success","code":200,"message":"OK","data":{}}"#)
        }
        do {
            let _: APIResponse<EmptyPayload> = try await service.get(urlString: endpoint, headers: nil)
            XCTFail("HTTP failure must not return a success payload")
        } catch NetworkError.networkError(let message, _) {
            XCTAssertEqual(message, "Request failed (403)")
        }
    }

    private static let refreshResponse = #"{"status":"success","code":200,"message":"OK","data":{"accessToken":"new-access","refreshToken":"new-refresh"}}"#
    private static let permissionError = #"{"status":"error","code":403,"message":"Denied","data":{"errorType":"PERMISSION_ERROR","description":"Denied"}}"#

    @MainActor
    func testMissingPINCannotAuthenticateWithEmptyInput() async throws {
        KeychainHelper.remove(.accessPin)
        let container = try ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let interactor = AuthenticationInteractor(modelContext: container.mainContext, networkService: MockNetworkService())
        let presenter = AuthenticationPresenter(interactor: interactor)
        presenter.inputPin = ""
        let valid = await presenter.isValidPin()
        XCTAssertFalse(valid)
    }
}

final class AnalysisResultPresenterTests: XCTestCase {
    @MainActor
    func testLoadingStaysActiveUntilRequestCompletes() async throws {
        let started = expectation(description: "Fetch started")
        let release = AsyncGate()
        let interactor = DelayedAnalysisInteractor(gate: release) { started.fulfill() }
        let presenter = AnalysisResultPresenter(interactor: interactor)
        let fetch = Task { await presenter.fetchData(examinationId: "test-exam") }
        await fulfillment(of: [started], timeout: 2)
        XCTAssertTrue(presenter.isLoading)
        await release.open()
        await fetch.value
        XCTAssertFalse(presenter.isLoading)
        XCTAssertNotNil(presenter.errorMessage)
    }
}

final class VideoUploadQueueTests: XCTestCase {
    @MainActor
    private func makeContext() throws -> ModelContext {
        let schema = Schema([PendingUpload.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @MainActor
    private func configure(_ queue: VideoUploadQueueService, context: ModelContext, connected: Bool = false) {
        let manager = NetworkRetryManager()
        manager.isConnected = connected
        queue.configure(
            modelContext: context,
            examInteractor: ExamInteractor(networkService: MockNetworkService()),
            networkRetryManager: manager
        )
    }

    @MainActor
    func testConfigurationRecoversInterruptedUploads() async throws {
        let context = try makeContext()
        let upload = PendingUpload(
            examinationId: UUID().uuidString.lowercased(), patientId: "patient", localFilePath: "/unused",
            slideId: "slide", state: .uploading, retryCount: 2
        )
        context.insert(upload)
        try context.save()
        let queue = VideoUploadQueueService()
        configure(queue, context: context)
        XCTAssertEqual(upload.state, .pending)
        XCTAssertEqual(upload.retryCount, 2)
        XCTAssertTrue(queue.hasPendingUpload(for: upload.examinationId))
    }

    @MainActor
    func testManualRetryResetsExhaustedAttempts() async throws {
        let context = try makeContext()
        let upload = PendingUpload(
            examinationId: UUID().uuidString.lowercased(), patientId: "patient", localFilePath: "/unused",
            slideId: "slide", state: .failed, retryCount: 5, lastError: "Previous failure"
        )
        context.insert(upload)
        try context.save()
        let queue = VideoUploadQueueService()
        configure(queue, context: context)
        await queue.retry(examinationId: upload.examinationId)
        XCTAssertEqual(upload.retryCount, 0)
        XCTAssertEqual(upload.state, .pending)
        XCTAssertNil(upload.lastError)
    }

    @MainActor
    func testEnqueuePreservesVideoFormat() async throws {
        let context = try makeContext()
        let queue = VideoUploadQueueService()
        configure(queue, context: context)
        let source = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        try Data("video".utf8).write(to: source)
        defer { try? FileManager.default.removeItem(at: source) }
        try await queue.enqueue(examinationId: "TEST-EXAM", patientId: "patient", slideId: "slide", sourceURL: source)
        let upload = try XCTUnwrap(context.fetch(FetchDescriptor<PendingUpload>()).first)
        defer { try? FileManager.default.removeItem(atPath: upload.localFilePath) }
        XCTAssertEqual(upload.examinationId, "test-exam")
        XCTAssertEqual(URL(fileURLWithPath: upload.localFilePath).pathExtension, "mp4")
        XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: upload.localFilePath)), Data("video".utf8))
    }

    @MainActor
    func testFailedReplacementKeepsOriginalVideo() async throws {
        let context = try makeContext()
        let queue = VideoUploadQueueService()
        configure(queue, context: context)
        let source = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
        try Data("original".utf8).write(to: source)
        defer { try? FileManager.default.removeItem(at: source) }
        try await queue.enqueue(examinationId: "replace", patientId: "patient", slideId: "slide", sourceURL: source)
        let upload = try XCTUnwrap(context.fetch(FetchDescriptor<PendingUpload>()).first)
        let originalPath = upload.localFilePath
        defer { try? FileManager.default.removeItem(atPath: upload.localFilePath) }
        do {
            try await queue.enqueue(
                examinationId: "replace", patientId: "patient", slideId: "slide",
                sourceURL: source.appendingPathExtension("missing")
            )
            XCTFail("Missing replacement should fail")
        } catch {}
        XCTAssertEqual(upload.localFilePath, originalPath)
        XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: originalPath)), Data("original".utf8))
    }

    @MainActor
    func testRetryDoesNotResetAnActiveUpload() async throws {
        let context = try makeContext()
        let upload = PendingUpload(
            examinationId: "active", patientId: "patient", localFilePath: "/unused", slideId: "slide"
        )
        context.insert(upload)
        try context.save()
        let queue = VideoUploadQueueService()
        configure(queue, context: context)
        upload.state = .uploading
        await queue.retry(examinationId: "active")
        XCTAssertEqual(upload.state, .uploading)
        do {
            try await queue.enqueue(
                examinationId: "active", patientId: "patient", slideId: "slide",
                sourceURL: URL(fileURLWithPath: "/unused")
            )
            XCTFail("Active uploads must not be replaced")
        } catch VideoUploadQueueError.uploadInProgress {}
    }

    @MainActor
    func testCancelledUploadKeepsVideoAndRetryBudget() async throws {
        let context = try makeContext()
        let source = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
        try Data("video".utf8).write(to: source)
        defer { try? FileManager.default.removeItem(at: source) }
        let upload = PendingUpload(
            examinationId: "cancelled", patientId: "patient", localFilePath: source.path,
            slideId: "slide", retryCount: 2
        )
        context.insert(upload)
        try context.save()
        let queue = VideoUploadQueueService()
        queue.configure(
            modelContext: context,
            examInteractor: CancelledExamInteractor(networkService: MockNetworkService()),
            networkRetryManager: NetworkRetryManager()
        )
        await queue.processQueue()
        XCTAssertEqual(upload.state, .pending)
        XCTAssertEqual(upload.retryCount, 2)
        XCTAssertNil(upload.lastError)
        XCTAssertNil(queue.uploadingExaminationId)
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
    }

    @MainActor
    func testMissingVideoRemainsVisibleAsFailure() async throws {
        let context = try makeContext()
        let upload = PendingUpload(
            examinationId: "missing", patientId: "patient", localFilePath: "/missing-\(UUID())", slideId: "slide"
        )
        context.insert(upload)
        try context.save()
        let queue = VideoUploadQueueService()
        configure(queue, context: context, connected: true)
        await queue.processQueue()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PendingUpload>()), 1)
        XCTAssertEqual(upload.state, .failed)
        XCTAssertEqual(upload.lastError, AppTextExam.uploadQueueMissingFile)
        await queue.processQueue()
        XCTAssertEqual(upload.lastError, AppTextExam.uploadQueueMissingFile)
    }
}

private struct EmptyPayload: Decodable {}
private struct ValuePayload: Decodable { let value: Int }

private final class CancelledExamInteractor: ExamInteractor {
    override func submitExamination(
        videoFileURL: URL, examinationId: String, patientId: String
    ) async throws -> APIResponse<ForwardVideoToMLData> {
        throw CancellationError()
    }
}

private final class DelayedAnalysisInteractor: AnalysisResultInteractor {
    private let gate: AsyncGate
    private let onStart: () -> Void

    init(gate: AsyncGate, onStart: @escaping () -> Void) {
        self.gate = gate
        self.onStart = onStart
        super.init(networkService: MockNetworkService())
    }

    override func fetchData(examId: String) async throws -> ExaminationResultData {
        onStart()
        await gate.wait()
        throw URLError(.notConnectedToInternet)
    }
}

private actor AsyncGate {
    private var isOpen = false
    private var continuation: CheckedContinuation<Void, Never>?

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { continuation = $0 }
    }

    func open() {
        isOpen = true
        continuation?.resume()
        continuation = nil
    }
}

private final class RequestLog: @unchecked Sendable {
    private let lock = NSLock()
    private var entries: [String] = []

    var values: [String] {
        lock.lock()
        defer { lock.unlock() }
        return entries
    }

    func append(_ value: String) {
        lock.lock()
        defer { lock.unlock() }
        entries.append(value)
    }
}

private final class StubURLProtocol: URLProtocol {
    private static let lock = NSLock()
    private static var storedHandler: ((URLRequest) throws -> (Int, String))?

    static var handler: ((URLRequest) throws -> (Int, String))? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storedHandler
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            storedHandler = newValue
        }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            guard let handler = Self.handler else { throw URLError(.unsupportedURL) }
            let (status, body) = try handler(request)
            let response = HTTPURLResponse(
                url: request.url!, statusCode: status, httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
