import Alamofire
import SwiftData
import XCTest
@testable import Oculab

final class QueueOwnershipTests: XCTestCase {
    @MainActor
    private func makeContext() throws -> ModelContext {
        let schema = Schema([PendingUpload.self])
        return try ModelContext(ModelContainer(
            for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        ))
    }

    @MainActor
    private func row(_ id: String, owner: String?, state: PendingUploadState = .pending) -> PendingUpload {
        PendingUpload(examinationId: id, patientId: "patient", localFilePath: "/not-used",
                      slideId: "slide", ownerUserId: owner, state: state)
    }

    @MainActor
    private func configure(_ queue: VideoUploadQueueService, context: ModelContext,
                           interactor: ExamInteractor = ExamInteractor(networkService: MockNetworkService()),
                           online: Bool = false) {
        let network = NetworkRetryManager(monitorsConnectivity: false)
        network.isConnected = online
        queue.configure(modelContext: context, examInteractor: interactor, networkRetryManager: network)
    }

    @MainActor
    func testOnlyActiveOwnerCanSeeOrRetryRows() async throws {
        let context = try makeContext()
        let own = row("own", owner: "a", state: .failed)
        let other = row("other", owner: "b", state: .failed)
        let legacy = row("legacy", owner: nil, state: .failed)
        for upload in [own, other, legacy] {
            upload.retryCount = 5
            upload.lastError = "saved error"
            context.insert(upload)
        }
        try context.save()
        let identity = OwnershipSessionBox(owner: "a")
        let queue = VideoUploadQueueService(sessionProvider: { identity.session })
        configure(queue, context: context)

        XCTAssertEqual(queue.pendingCount, 1)
        XCTAssertEqual(queue.failedExaminationIds, ["own"])
        XCTAssertEqual(queue.uploadState(for: "own"), .failed)
        XCTAssertFalse(queue.hasPendingUpload(for: "other"))
        XCTAssertNil(queue.uploadState(for: "legacy"))
        XCTAssertNil(queue.lastUploadError(for: "other"))
        await queue.retry(examinationId: "other")
        await queue.retry(examinationId: "legacy")
        XCTAssertEqual(other.retryCount, 5)
        XCTAssertEqual(legacy.retryCount, 5)

        identity.session = nil
        queue.sessionDidChange()
        XCTAssertEqual(queue.pendingCount, 0)
        XCTAssertTrue(queue.failedExaminationIds.isEmpty)
        XCTAssertNil(queue.lastUploadError(for: "own"))
        XCTAssertFalse(queue.hasPendingUpload(for: "own"))

        identity.session = UploadQueueSession(ownerUserId: "b", generation: UUID())
        queue.sessionDidChange()
        XCTAssertEqual(queue.pendingCount, 1)
        XCTAssertEqual(queue.failedExaminationIds, ["other"])
    }

    @MainActor
    func testEnqueueCapturesOwnerAndNeverClaimsLegacyVideo() async throws {
        let context = try makeContext()
        let legacy = row("legacy", owner: nil)
        context.insert(legacy)
        try context.save()
        let identity = OwnershipSessionBox(owner: "a")
        let queue = VideoUploadQueueService(sessionProvider: { identity.session })
        configure(queue, context: context)
        let source = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        try Data("video".utf8).write(to: source)
        defer { try? FileManager.default.removeItem(at: source) }

        do {
            try await queue.enqueue(examinationId: "legacy", patientId: "patient", slideId: "slide", sourceURL: source)
            XCTFail("Unowned legacy videos must not be assigned to the next login")
        } catch VideoUploadQueueError.legacyOwnershipUnknown {}
        XCTAssertNil(legacy.ownerUserId)
        XCTAssertEqual(legacy.localFilePath, "/not-used")

        try await queue.enqueue(examinationId: "new", patientId: "patient", slideId: "slide", sourceURL: source)
        let created = try XCTUnwrap(context.fetch(FetchDescriptor<PendingUpload>()).first { $0.examinationId == "new" })
        defer { try? FileManager.default.removeItem(atPath: created.localFilePath) }
        XCTAssertEqual(created.ownerUserId, "a")

        identity.session = UploadQueueSession(ownerUserId: "b", generation: UUID())
        queue.sessionDidChange()
        do {
            try await queue.enqueue(examinationId: "new", patientId: "patient", slideId: "slide", sourceURL: source)
            XCTFail("Another account cannot overwrite a saved video")
        } catch VideoUploadQueueError.differentOwner {}
        XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: created.localFilePath)), Data("video".utf8))

        identity.session = nil
        queue.sessionDidChange()
        do {
            try await queue.enqueue(examinationId: "logged-out", patientId: "patient", slideId: "slide", sourceURL: source)
            XCTFail("Queueing requires an authenticated owner")
        } catch VideoUploadQueueError.authenticationRequired {}
    }

    @MainActor
    func testLateSuccessAfterAccountSwitchPreservesOriginalFileAndRetryBudget() async throws {
        let context = try makeContext()
        let identity = OwnershipSessionBox(owner: "a")
        let queue = VideoUploadQueueService(sessionProvider: { identity.session })
        let started = expectation(description: "Upload started")
        let gate = OwnershipGate()
        let interactor = OwnershipExamInteractor { _ in
            started.fulfill()
            await gate.wait()
            // Simulates a transport that delivers its receipt after cancellation.
            return APIResponse(status: "success", code: 200, message: "accepted", data: ForwardVideoToMLData(
                examinationId: "switch", statusExamination: .INPROGRESS, statusML: "queued"
            ))
        }
        configure(queue, context: context, interactor: interactor, online: false)
        let source = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        try Data("original video".utf8).write(to: source)
        defer { try? FileManager.default.removeItem(at: source) }
        try await queue.enqueue(examinationId: "switch", patientId: "patient", slideId: "slide", sourceURL: source)
        let upload = try XCTUnwrap(context.fetch(FetchDescriptor<PendingUpload>()).first)
        defer { try? FileManager.default.removeItem(atPath: upload.localFilePath) }
        upload.retryCount = 2
        let network = NetworkRetryManager(monitorsConnectivity: false)
        network.isConnected = true
        queue.configure(modelContext: context, examInteractor: interactor, networkRetryManager: network)
        let worker = Task { await queue.processQueue() }
        await fulfillment(of: [started], timeout: 2)
        XCTAssertEqual(upload.state, .uploading)

        identity.session = UploadQueueSession(ownerUserId: "b", generation: UUID())
        queue.sessionDidChange()
        XCTAssertNil(queue.uploadingExaminationId)
        XCTAssertEqual(queue.pendingCount, 0)
        await gate.open()
        await worker.value

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PendingUpload>()), 1)
        XCTAssertEqual(upload.ownerUserId, "a")
        XCTAssertEqual(upload.state, .pending)
        XCTAssertEqual(upload.retryCount, 2)
        XCTAssertTrue(FileManager.default.fileExists(atPath: upload.localFilePath))
        XCTAssertFalse(AnalysisTrackingStore.isTracked("switch"))
        identity.session = UploadQueueSession(ownerUserId: "a", generation: UUID())
        queue.sessionDidChange()
        XCTAssertTrue(queue.hasPendingUpload(for: "switch"))
    }

    @MainActor
    func testLoggedOutAndLegacyRowsNeverStartRequests() async throws {
        let context = try makeContext()
        let identity = OwnershipSessionBox(owner: nil)
        let queue = VideoUploadQueueService(sessionProvider: { identity.session })
        let legacy = row("legacy", owner: nil, state: .uploading)
        let original = row("original", owner: "a")
        context.insert(legacy)
        context.insert(original)
        try context.save()
        let interactor = OwnershipExamInteractor { _ in
            XCTFail("Rows without an active matching owner must not be sent")
            throw CancellationError()
        }
        configure(queue, context: context, interactor: interactor, online: true)
        await queue.processQueue()
        XCTAssertEqual(original.retryCount, 0)
        identity.session = UploadQueueSession(ownerUserId: "b", generation: UUID())
        queue.sessionDidChange()
        await queue.processQueue()
        XCTAssertNil(legacy.ownerUserId)
        XCTAssertEqual(legacy.state, .uploading)
        XCTAssertEqual(original.retryCount, 0)
        XCTAssertEqual(queue.pendingCount, 0)
    }

    @MainActor
    func testReturningOwnerRecoversInterruptedUploadFromLoggedOutColdStart() async throws {
        let context = try makeContext()
        let identity = OwnershipSessionBox(owner: nil)
        let queue = VideoUploadQueueService(sessionProvider: { identity.session })
        let interrupted = row("interrupted", owner: "a", state: .uploading)
        interrupted.retryCount = 2
        context.insert(interrupted)
        try context.save()
        configure(queue, context: context)
        XCTAssertEqual(interrupted.state, .uploading)
        identity.session = UploadQueueSession(ownerUserId: "b", generation: UUID())
        queue.sessionDidChange()
        XCTAssertEqual(interrupted.state, .uploading)
        identity.session = UploadQueueSession(ownerUserId: "a", generation: UUID())
        queue.sessionDidChange()
        XCTAssertEqual(interrupted.state, .pending)
        XCTAssertEqual(interrupted.retryCount, 2)
        XCTAssertEqual(queue.uploadState(for: "interrupted"), .pending)
    }
}

final class QueueSessionEpochTests: XCTestCase {
    @MainActor
    private func withSessionFixture(_ body: (AlamofireNetworkService, EpochRequests) async throws -> Void) async throws {
        let keychainKeys: [KeychainKey] = [.accessToken, .refreshToken, .accessPin]
        let previousSecrets = keychainKeys.map { ($0, KeychainHelper.string(for: $0)) }
        let previousDefaults = UserDefaultType.allCases.map { ($0, UserDefaults.standard.object(forKey: $0.rawValue)) }
        defer {
            EpochURLProtocol.handler = nil
            AuthSessionManager.beginSessionChange()
            for (key, value) in previousSecrets {
                if let value { KeychainHelper.set(value, for: key) }
                else { KeychainHelper.remove(key) }
            }
            for (key, value) in previousDefaults { UserDefaults.standard.set(value, forKey: key.rawValue) }
            AuthSessionManager.completeSessionChange()
        }
        setSession(owner: "a")
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [EpochURLProtocol.self]
        let service = AlamofireNetworkService(session: Session(configuration: configuration))
        try await body(service, EpochRequests())
    }

    @MainActor
    private func setSession(owner: String) {
        AuthSessionManager.beginSessionChange()
        XCTAssertTrue(KeychainHelper.set("\(owner)-access", for: .accessToken))
        XCTAssertTrue(KeychainHelper.set("\(owner)-refresh", for: .refreshToken))
        UserDefaults.standard.set(owner, forKey: UserDefaultType.userId.rawValue)
        UserDefaults.standard.set(true, forKey: UserDefaultType.isUserLoggedIn.rawValue)
        AuthSessionManager.completeSessionChange()
    }

    @MainActor
    func testLateOld401CannotRefreshOrInvalidateNewAccount() async throws {
        try await withSessionFixture { service, requests in
            let started = expectation(description: "Original account request started")
            EpochURLProtocol.handler = { request in
                requests.hold(request)
                started.fulfill()
            }
            let task = Task {
                let _: APIResponse<EpochPayload> = try await service.get(
                    urlString: API.BE + "/examination/epoch-check", headers: nil
                )
            }
            await fulfillment(of: [started], timeout: 2)
            setSession(owner: "b")
            requests.release(status: 401, body: "{}")
            do {
                try await task.value
                XCTFail("Response belongs to a superseded session")
            } catch is CancellationError {}
            XCTAssertEqual(requests.count, 1, "Old 401 must not issue a refresh with B's token")
            XCTAssertEqual(KeychainHelper.string(for: .accessToken), "b-access")
            XCTAssertEqual(KeychainHelper.string(for: .refreshToken), "b-refresh")
            XCTAssertTrue(UserDefaults.standard.bool(forKey: UserDefaultType.isUserLoggedIn.rawValue))
        }
    }

    @MainActor
    func testLateRefreshSuccessCannotOverwriteNewAccountsCredentials() async throws {
        try await withSessionFixture { service, requests in
            let refreshing = expectation(description: "Original account refresh started")
            EpochURLProtocol.handler = { request in
                if request.request.url!.path.contains("refresh-token") {
                    requests.hold(request)
                    refreshing.fulfill()
                } else {
                    requests.record()
                    request.respond(status: 401, body: "{}")
                }
            }
            let task = Task {
                let _: APIResponse<EpochPayload> = try await service.get(
                    urlString: API.BE + "/examination/epoch-check", headers: nil
                )
            }
            await fulfillment(of: [refreshing], timeout: 2)
            setSession(owner: "b")
            requests.release(status: 200, body: #"{"status":"success","code":200,"message":"OK","data":{"accessToken":"stale-a-access","refreshToken":"stale-a-refresh"}}"#)
            do {
                try await task.value
                XCTFail("Stale refresh must not commit credentials")
            } catch is CancellationError {}
            XCTAssertEqual(requests.count, 2, "No protected request may be retried under B")
            XCTAssertEqual(KeychainHelper.string(for: .accessToken), "b-access")
            XCTAssertEqual(KeychainHelper.string(for: .refreshToken), "b-refresh")
        }
    }

    @MainActor
    func testLogoutPreservesStoreVersionSoColdLaunchDoesNotWipeQueuedVideos() async throws {
        try await withSessionFixture { _, _ in
            let versionKey = UserDefaultType.swiftDataSchemaVersion.rawValue
            let previousVersion = UserDefaults.standard.object(forKey: versionKey)
            defer { UserDefaults.standard.set(previousVersion, forKey: versionKey) }
            UserDefaults.standard.set(3, forKey: versionKey)
            let schema = Schema([User.self, PendingUpload.self])
            let container = try ModelContainer(
                for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
            let context = container.mainContext
            let pending = PendingUpload(examinationId: "logout", patientId: "patient", localFilePath: "/saved-video",
                                        slideId: "slide", ownerUserId: "a")
            context.insert(pending)
            try context.save()
            let presenter = AuthenticationPresenter(interactor: AuthenticationInteractor(
                modelContext: context, networkService: MockNetworkService()
            ))
            await presenter.performLogout()
            XCTAssertEqual(UserDefaults.standard.integer(forKey: versionKey), 3)
            XCTAssertEqual(try context.fetchCount(FetchDescriptor<PendingUpload>()), 1)
            XCTAssertEqual(pending.ownerUserId, "a")
            XCTAssertNil(AuthSessionManager.uploadQueueSession)
        }
    }

    @MainActor
    func testDelayedInvalidationLogoutCannotClearNewSessionsUserOrQueue() async throws {
        try await withSessionFixture { _, _ in
            let schema = Schema([User.self, PendingUpload.self])
            let container = try ModelContainer(
                for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
            let context = container.mainContext
            let presenter = AuthenticationPresenter(interactor: AuthenticationInteractor(
                modelContext: context, networkService: MockNetworkService()
            ))
            let capture = EpochNotificationCapture()
            let observer = NotificationCenter.default.addObserver(
                forName: AuthSessionManager.sessionDidInvalidateNotification, object: nil, queue: nil
            ) { notification in capture.record(notification) }
            defer { NotificationCenter.default.removeObserver(observer) }
            AuthSessionManager.invalidateSession()
            let invalidatedGeneration = try XCTUnwrap(capture.generation)
            XCTAssertEqual(invalidatedGeneration, AuthSessionManager.authenticationSessionGeneration)

            // Mirrors AccountCheckerView's queued main-actor logout after invalidation.
            let delayedLogout = Task { @MainActor in
                await presenter.performLogout(ifGeneration: invalidatedGeneration)
            }
            setSession(owner: "b")
            let bGeneration = AuthSessionManager.authenticationSessionGeneration
            let currentUser = User(id: "b", name: "Current user")
            let pending = PendingUpload(examinationId: "b-pending", patientId: "patient", localFilePath: "/b-video",
                                        slideId: "slide", ownerUserId: "b")
            context.insert(currentUser)
            context.insert(pending)
            try context.save()
            presenter.user = currentUser
            presenter.isPinAuthorized = true
            await delayedLogout.value

            XCTAssertEqual(AuthSessionManager.authenticationSessionGeneration, bGeneration)
            XCTAssertEqual(KeychainHelper.string(for: .accessToken), "b-access")
            XCTAssertEqual(KeychainHelper.string(for: .refreshToken), "b-refresh")
            XCTAssertEqual(UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue), "b")
            XCTAssertTrue(UserDefaults.standard.bool(forKey: UserDefaultType.isUserLoggedIn.rawValue))
            XCTAssertEqual(try context.fetch(FetchDescriptor<User>()).first?.id, "b")
            XCTAssertEqual(presenter.user.id, "b")
            XCTAssertTrue(presenter.isPinAuthorized)
            XCTAssertEqual(try context.fetchCount(FetchDescriptor<PendingUpload>()), 1)
            XCTAssertEqual(pending.ownerUserId, "b")
        }
    }
}

private struct EpochPayload: Decodable {}

private final class EpochNotificationCapture: @unchecked Sendable {
    private let lock = NSLock()
    private var capturedGeneration: UUID?
    var generation: UUID? {
        lock.lock()
        defer { lock.unlock() }
        return capturedGeneration
    }
    func record(_ notification: Notification) {
        lock.lock()
        capturedGeneration = notification.userInfo?[AuthSessionManager.invalidatedSessionGenerationKey] as? UUID
        lock.unlock()
    }
}

private final class EpochRequests: @unchecked Sendable {
    private let lock = NSLock()
    private var pending: EpochURLProtocol?
    private var requestCount = 0
    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return requestCount
    }
    func record() {
        lock.lock()
        requestCount += 1
        lock.unlock()
    }
    func hold(_ request: EpochURLProtocol) {
        lock.lock()
        requestCount += 1
        pending = request
        lock.unlock()
    }
    func release(status: Int, body: String) {
        lock.lock()
        let request = pending
        pending = nil
        lock.unlock()
        request?.respond(status: status, body: body)
    }
}

private final class EpochURLProtocol: URLProtocol {
    static var handler: ((EpochURLProtocol) -> Void)?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() { Self.handler?(self) }
    override func stopLoading() {}
    func respond(status: Int, body: String) {
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
}

@MainActor
private final class OwnershipSessionBox {
    var session: UploadQueueSession?
    init(owner: String?) {
        session = owner.map { UploadQueueSession(ownerUserId: $0, generation: UUID()) }
    }
}

private actor OwnershipGate {
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

private final class OwnershipExamInteractor: ExamInteractor {
    private let behavior: @MainActor (String) async throws -> APIResponse<ForwardVideoToMLData>
    init(behavior: @escaping @MainActor (String) async throws -> APIResponse<ForwardVideoToMLData>) {
        self.behavior = behavior
        super.init(networkService: MockNetworkService())
    }
    override func submitExamination(videoFileURL: URL, examinationId: String, patientId: String) async throws -> APIResponse<ForwardVideoToMLData> {
        try await behavior(examinationId)
    }
}
