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

final class TaskAssignmentRepositoryTests: XCTestCase {
    func testExistingLookupFailureNeverCreatesAnotherPatient() async throws {
        let patientID = UUID().uuidString.lowercased()
        let errors: [Error] = [
            URLError(.timedOut), URLError(.cancelled), CancellationError(), NetworkError.unauthorized(),
            NetworkError.apiError(APIResponse(
                status: "error", code: 404, message: "Missing",
                data: ApiErrorData(errorType: "RESOURCE_NOT_FOUND", description: "Missing patient")
            )),
        ]
        for error in errors {
            let creates = RequestLog()
            let interactor = TaskAssignmentStubInteractor(
                lookup: { _ in throw error },
                create: { patient in creates.append("created"); return patient }
            )
            let repository = TaskAssignmentRepository(interactor: interactor)
            do {
                _ = try await repository.ensurePatientOnServer(draft: Self.patient(), preferredId: patientID)
                XCTFail("Existing-patient lookup errors must propagate")
            } catch {}
            XCTAssertTrue(creates.values.isEmpty)
        }
    }

    func testExistingPatientReturnsCanonicalRecordWithoutCreation() async throws {
        let patientID = UUID().uuidString.lowercased()
        let canonical = Self.patient(id: patientID, name: "Canonical")
        let creates = RequestLog()
        let interactor = TaskAssignmentStubInteractor(
            lookup: { id in XCTAssertEqual(id, patientID); return canonical },
            create: { patient in creates.append("created"); return patient }
        )
        let result = try await TaskAssignmentRepository(interactor: interactor).ensurePatientOnServer(
            draft: Self.patient(), preferredId: " \(patientID) "
        )
        XCTAssertTrue(result === canonical)
        XCTAssertTrue(creates.values.isEmpty)
    }

    func testNewPatientIsCreatedOnce() async throws {
        let creates = RequestLog()
        let draft = Self.patient()
        let interactor = TaskAssignmentStubInteractor(create: { patient in
            creates.append(patient.name)
            return patient
        })
        let result = try await TaskAssignmentRepository(interactor: interactor).ensurePatientOnServer(
            draft: draft, preferredId: nil
        )
        XCTAssertTrue(result === draft)
        XCTAssertEqual(creates.values, [draft.name])
    }

    func testExistingLegacyIDIsLookedUpWithoutCreatingReplacement() async throws {
        let legacyID = "507f1f77bcf86cd799439011"
        let creates = RequestLog()
        let lookups = RequestLog()
        let interactor = TaskAssignmentStubInteractor(
            lookup: { id in lookups.append(id); return Self.patient(id: id) },
            create: { patient in creates.append("created"); return patient }
        )
        let result = try await TaskAssignmentRepository(interactor: interactor).ensurePatientOnServer(
            draft: Self.patient(), preferredId: legacyID
        )
        XCTAssertEqual(result.id, legacyID)
        XCTAssertEqual(lookups.values, [legacyID])
        XCTAssertTrue(creates.values.isEmpty)
    }

    func testInvalidNewPatientDoesNotMutateDraftOrSendRequest() async throws {
        for name in ["", "   ", UUID().uuidString] {
            let creates = RequestLog()
            let draft = Self.patient(name: name)
            let interactor = TaskAssignmentStubInteractor(create: { patient in
                creates.append(patient.name)
                return patient
            })
            do {
                _ = try await TaskAssignmentRepository(interactor: interactor).ensurePatientOnServer(
                    draft: draft, preferredId: nil
                )
                XCTFail("Invalid draft should be rejected")
            } catch TaskAssignmentFlowError.patientDataIncomplete {}
            XCTAssertEqual(draft.name, name)
            XCTAssertTrue(creates.values.isEmpty)
        }
    }

    fileprivate static func patient(id: String = "", name: String = "Test patient") -> Patient {
        Patient(id: id, name: name, NIK: "1234567890123456", DoB: Date(timeIntervalSince1970: 0), sex: .MALE)
    }
}

final class TaskAssignmentSelectionTests: XCTestCase {
    @MainActor
    func testLatePatientResponseCannotOverwriteNewSelection() async throws {
        await assertStaleLookupIsIgnored(fails: false)
    }

    @MainActor
    func testLatePatientFailureCannotClearNewSelection() async throws {
        await assertStaleLookupIsIgnored(fails: true)
    }

    @MainActor
    private func assertStaleLookupIsIgnored(fails: Bool) async {
        let oldID = UUID().uuidString.lowercased()
        let newID = UUID().uuidString.lowercased()
        let started = expectation(description: "Old lookup started")
        let gate = AsyncGate()
        let interactor = TaskAssignmentStubInteractor(lookup: { id in
            if id == oldID {
                started.fulfill()
                await gate.wait()
                if fails { throw URLError(.timedOut) }
            }
            return TaskAssignmentRepositoryTests.patient(id: id, name: id == oldID ? "Old" : "New")
        })
        let coordinator = TaskAssignmentFlowCoordinator(repository: TaskAssignmentRepository(interactor: interactor))
        coordinator.patientSelection = .existing(patientId: oldID)
        let oldLookup = Task { await coordinator.handlePatientChoiceChange() }
        await fulfillment(of: [started], timeout: 2)
        coordinator.patientSelection = .existing(patientId: newID)
        await coordinator.handlePatientChoiceChange()
        await gate.open()
        await oldLookup.value
        XCTAssertEqual(coordinator.patient.id, newID)
        XCTAssertEqual(coordinator.savedPatientId, newID)
        XCTAssertEqual(coordinator.patientSelection, .existing(patientId: newID))
        XCTAssertFalse(coordinator.isError)
        XCTAssertFalse(coordinator.isPatientLoading)
    }

    @MainActor
    func testClearingSelectionInvalidatesPendingLookupAndDraft() async throws {
        let id = UUID().uuidString.lowercased()
        let started = expectation(description: "Lookup started")
        let gate = AsyncGate()
        let interactor = TaskAssignmentStubInteractor(lookup: { id in
            started.fulfill()
            await gate.wait()
            return TaskAssignmentRepositoryTests.patient(id: id)
        })
        let coordinator = TaskAssignmentFlowCoordinator(repository: TaskAssignmentRepository(interactor: interactor))
        coordinator.patientSelection = .existing(patientId: id)
        let lookup = Task { await coordinator.handlePatientChoiceChange() }
        await fulfillment(of: [started], timeout: 2)
        coordinator.updatePatientChoice("")
        XCTAssertFalse(coordinator.isPatientLoading)
        await gate.open()
        await lookup.value
        XCTAssertNil(coordinator.patientSelection)
        XCTAssertTrue(coordinator.patient.id.isEmpty)
        XCTAssertTrue(coordinator.patient.name.isEmpty)
        XCTAssertTrue(coordinator.savedPatientId.isEmpty)
        XCTAssertFalse(coordinator.patientFound)
    }

    @MainActor
    func testCancelledLookupDoesNotPopulatePatient() async throws {
        let started = expectation(description: "Lookup started")
        let gate = AsyncGate()
        let interactor = TaskAssignmentStubInteractor(lookup: { id in
            started.fulfill()
            await gate.wait()
            return TaskAssignmentRepositoryTests.patient(id: id)
        })
        let coordinator = TaskAssignmentFlowCoordinator(repository: TaskAssignmentRepository(interactor: interactor))
        coordinator.patientSelection = .existing(patientId: UUID().uuidString.lowercased())
        let lookup = Task { await coordinator.handlePatientChoiceChange() }
        await fulfillment(of: [started], timeout: 2)
        lookup.cancel()
        await gate.open()
        await lookup.value
        XCTAssertTrue(coordinator.patient.id.isEmpty)
        XCTAssertFalse(coordinator.patientFound)
        XCTAssertFalse(coordinator.isPatientLoading)
        XCTAssertFalse(coordinator.isError)
    }

    @MainActor
    func testChangedPatientCannotProceedWithPreviousPatientData() async throws {
        let oldID = UUID().uuidString.lowercased()
        let interactor = TaskAssignmentStubInteractor(lookup: { id in
            TaskAssignmentRepositoryTests.patient(id: id)
        })
        let coordinator = TaskAssignmentFlowCoordinator(repository: TaskAssignmentRepository(interactor: interactor))
        coordinator.selectedPIC = "selected-pic"
        coordinator.patientSelection = .existing(patientId: oldID)
        await coordinator.handlePatientChoiceChange()
        XCTAssertTrue(coordinator.isPatientStepReady)
        coordinator.patientSelection = .existing(patientId: UUID().uuidString.lowercased())
        XCTAssertFalse(coordinator.isPatientStepReady)
        XCTAssertFalse(coordinator.validatePatientStepBeforeProceed())
    }

    @MainActor
    func testLatePICResponseCannotOverwriteNewChoice() async throws {
        let started = expectation(description: "Old PIC lookup started")
        let gate = AsyncGate()
        let interactor = TaskAssignmentStubInteractor(userLookup: { id in
            if id == "old-pic" {
                started.fulfill()
                await gate.wait()
            }
            return User(id: id, name: id, role: .LAB)
        })
        let coordinator = TaskAssignmentFlowCoordinator(repository: TaskAssignmentRepository(interactor: interactor))
        coordinator.selectedPIC = "old-pic"
        let oldLookup = Task { await coordinator.getUserById(userId: "old-pic") }
        await fulfillment(of: [started], timeout: 2)
        coordinator.selectedPIC = "new-pic"
        await coordinator.getUserById(userId: "new-pic")
        await gate.open()
        await oldLookup.value
        XCTAssertEqual(coordinator.pic.id, "new-pic")
        XCTAssertFalse(coordinator.isUserLoading)
    }

    @MainActor
    func testSpecimenSubmissionUsesRoutePICInsteadOfStaleUserRecord() async throws {
        let defaults = UserDefaults.standard
        let key = UserDefaultType.userId.rawValue
        let savedID = defaults.object(forKey: key)
        defaults.set("dpjp", forKey: key)
        defer {
            if let savedID { defaults.set(savedID, forKey: key) } else { defaults.removeObject(forKey: key) }
        }
        let submissions = RequestLog()
        let interactor = TaskAssignmentStubInteractor(
            lookup: { id in TaskAssignmentRepositoryTests.patient(id: id) },
            examinations: { _, requests in
                submissions.append(requests.first?.PIC ?? "")
                let data = Data(#"{"id":"created","goal":"SCREENING","preparationType":"SP","slideId":"slide","statusExamination":"NOTSTARTED"}"#.utf8)
                return try JSONDecoder().decode(ExaminationDataResponse.self, from: data)
            }
        )
        let coordinator = TaskAssignmentFlowCoordinator(repository: TaskAssignmentRepository(interactor: interactor))
        coordinator.attachSpecimenRouteContext(patientId: UUID().uuidString.lowercased(), picId: "route-pic")
        coordinator.pic = User(id: "stale-pic", name: "Stale", role: .LAB)
        coordinator.examination.goal = .SCREENING
        coordinator.examination.preparationType = .SP
        coordinator.examination.slideId = "slide"
        await coordinator.submitExamination()
        XCTAssertEqual(submissions.values, ["route-pic"])
        XCTAssertFalse(coordinator.isError)
    }

    @MainActor
    func testSavingNewPatientCanonicalizesSelection() async throws {
        let id = UUID().uuidString.lowercased()
        let interactor = TaskAssignmentStubInteractor(create: { patient in
            TaskAssignmentRepositoryTests.patient(id: id, name: patient.name)
        })
        let coordinator = TaskAssignmentFlowCoordinator(repository: TaskAssignmentRepository(interactor: interactor))
        coordinator.prepareNewPatientSelection(name: "New patient")
        coordinator.patient = TaskAssignmentRepositoryTests.patient(name: "New patient")
        coordinator.selectedSex = AppPatient.Gender.male
        coordinator.selectedPIC = "selected-pic"
        coordinator.pic = User(id: "stale-pic", name: "Stale", role: .LAB)
        await coordinator.proceedToSpecimenStep()
        defer { Router.shared.popToRoot() }
        XCTAssertEqual(coordinator.patientSelection, .existing(patientId: id))
        XCTAssertEqual(coordinator.savedPatientId, id)
        XCTAssertEqual(coordinator.examinationPICId, "selected-pic")
        XCTAssertTrue(coordinator.isPatientStepReady)
        XCTAssertFalse(coordinator.isError)
    }

    @MainActor
    func testLateSaveCannotRestorePreviousPatientChoice() async throws {
        let id = UUID().uuidString.lowercased()
        let started = expectation(description: "Save lookup started")
        let gate = AsyncGate()
        let calls = RequestLog()
        let interactor = TaskAssignmentStubInteractor(lookup: { id in
            calls.append(id)
            if calls.values.count == 2 {
                started.fulfill()
                await gate.wait()
            }
            return TaskAssignmentRepositoryTests.patient(id: id)
        })
        let coordinator = TaskAssignmentFlowCoordinator(repository: TaskAssignmentRepository(interactor: interactor))
        coordinator.patientSelection = .existing(patientId: id)
        coordinator.selectedPIC = "old-pic"
        await coordinator.handlePatientChoiceChange()
        let save = Task { await coordinator.proceedToSpecimenStep() }
        await fulfillment(of: [started], timeout: 2)
        coordinator.prepareNewPatientSelection(name: "New choice")
        coordinator.selectedPIC = "new-pic"
        await gate.open()
        await save.value
        XCTAssertEqual(coordinator.patientSelection, .new(displayName: "New choice"))
        XCTAssertEqual(coordinator.patient.name, "New choice")
        XCTAssertTrue(coordinator.savedPatientId.isEmpty)
        XCTAssertTrue(coordinator.examinationPICId.isEmpty)
        XCTAssertFalse(coordinator.isSavingPatient)
        XCTAssertFalse(coordinator.isError)
    }

    @MainActor
    func testLeavingPatientStepCancelsSaveBeforeNavigation() async throws {
        let id = UUID().uuidString.lowercased()
        let started = expectation(description: "Save lookup started")
        let gate = AsyncGate()
        let calls = RequestLog()
        let interactor = TaskAssignmentStubInteractor(lookup: { id in
            calls.append(id)
            if calls.values.count == 2 {
                started.fulfill()
                await gate.wait()
            }
            return TaskAssignmentRepositoryTests.patient(id: id)
        })
        let coordinator = TaskAssignmentFlowCoordinator(repository: TaskAssignmentRepository(interactor: interactor))
        coordinator.patientSelection = .existing(patientId: id)
        coordinator.selectedPIC = "selected-pic"
        await coordinator.handlePatientChoiceChange()
        let save = coordinator.newExam()
        await fulfillment(of: [started], timeout: 2)
        coordinator.cancelPendingPatientSave()
        await gate.open()
        await save.value
        XCTAssertTrue(coordinator.examinationPICId.isEmpty)
        XCTAssertFalse(coordinator.isSavingPatient)
        XCTAssertFalse(coordinator.isError)
    }
}

private final class TaskAssignmentStubInteractor: InputPatientInteractor {
    private let lookup: (String) async throws -> Patient
    private let create: (Patient) async throws -> Patient
    private let userLookup: (String) async throws -> User
    private let examinations: (String, [ExaminationRequest]) async throws -> ExaminationDataResponse

    init(
        lookup: @escaping (String) async throws -> Patient = { _ in throw URLError(.unsupportedURL) },
        create: @escaping (Patient) async throws -> Patient = { _ in throw URLError(.unsupportedURL) },
        userLookup: @escaping (String) async throws -> User = { _ in throw URLError(.unsupportedURL) },
        examinations: @escaping (String, [ExaminationRequest]) async throws -> ExaminationDataResponse = { _, _ in
            throw URLError(.unsupportedURL)
        }
    ) {
        self.lookup = lookup
        self.create = create
        self.userLookup = userLookup
        self.examinations = examinations
        super.init(networkService: MockNetworkService())
    }

    override func getPatientById(patientId: String) async throws -> Patient { try await lookup(patientId) }
    override func addNewPatient(patient: Patient) async throws -> Patient { try await create(patient) }
    override func getUserById(userId: String) async throws -> User { try await userLookup(userId) }
    override func addNewExamination(patientId: String, examinations: [ExaminationRequest]) async throws -> ExaminationDataResponse {
        try await self.examinations(patientId, examinations)
    }
}
