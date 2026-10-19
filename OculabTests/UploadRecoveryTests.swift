import Alamofire
import SwiftData
import XCTest
@testable import Oculab

final class UploadRecoveryTests: XCTestCase {
    @MainActor
    private func fixture() async throws -> RecoveryFixture {
        let fixture = try RecoveryFixture()
        try await fixture.queue.enqueue(examinationId: "exam", patientId: "patient", slideId: "slide", sourceURL: fixture.source)
        fixture.upload = try XCTUnwrap(fixture.context.fetch(FetchDescriptor<PendingUpload>()).first)
        fixture.network.isConnected = true
        return fixture
    }

    @MainActor
    func testReplacementCreatesNewKeyAndChecksum() async throws {
        let f = try await fixture()
        defer { f.cleanup() }
        let originalKey = try XCTUnwrap(f.upload.submissionId)
        let originalPath = f.upload.localFilePath
        f.network.isConnected = false
        try Data("replacement".utf8).write(to: f.source)
        try await f.queue.enqueue(examinationId: "exam", patientId: "patient", slideId: "slide", sourceURL: f.source)
        XCTAssertNotEqual(f.upload.submissionId, originalKey)
        XCTAssertNotNil(f.upload.submissionId.flatMap(UUID.init(uuidString:)))
        let hash = try await VideoUploadQueueService.sha256(of: f.source)
        XCTAssertEqual(f.upload.videoSHA256, hash)
        XCTAssertFalse(FileManager.default.fileExists(atPath: originalPath))
        XCTAssertFalse(f.upload.needsReconciliation)
    }

    @MainActor
    func testLostResponseReconcilesAcceptedReceiptWithoutResendingBytes() async throws {
        let f = try await fixture()
        defer { f.cleanup() }
        f.interactor.submit = { _, _ in throw URLError(.networkConnectionLost) }
        await f.queue.processQueue()
        XCTAssertEqual(f.events.sends, 1)
        XCTAssertTrue(f.upload.needsReconciliation)
        XCTAssertTrue(FileManager.default.fileExists(atPath: f.upload.localFilePath))
        f.interactor.lookup = { exam, key in RecoveryFixture.receipt(exam, key, state: "accepted") }
        f.clock.date = try XCTUnwrap(f.upload.nextAttemptAt)
        await f.queue.processQueue()
        XCTAssertEqual(f.events.sends, 1)
        XCTAssertEqual(f.events.lookups, 1)
        XCTAssertEqual(f.events.accepted, ["exam"])
        XCTAssertEqual(try f.context.fetchCount(FetchDescriptor<PendingUpload>()), 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: f.upload.localFilePath))
    }

    @MainActor
    func testInterruptedUploadLooksUpReceiptBeforeAnySend() async throws {
        let f = try await fixture()
        defer { f.cleanup() }
        f.upload.state = .uploading
        f.upload.needsReconciliation = false
        try f.context.save()
        f.interactor.lookup = { exam, key in RecoveryFixture.receipt(exam, key, state: "accepted") }
        f.queue.configure(modelContext: f.context, examInteractor: f.interactor, networkRetryManager: f.network)
        await f.queue.processQueue()
        XCTAssertEqual(f.events.order, ["lookup"])
        XCTAssertEqual(f.events.accepted, ["exam"])
    }

    @MainActor
    func testPending202NeverDeletesVideoOrResendsWhileReceiptPending() async throws {
        let f = try await fixture()
        defer { f.cleanup() }
        f.interactor.submit = { exam, key in RecoveryFixture.response(exam, key, state: "pending", code: 202) }
        await f.queue.processQueue()
        XCTAssertTrue(FileManager.default.fileExists(atPath: f.upload.localFilePath))
        XCTAssertTrue(f.events.accepted.isEmpty)
        f.interactor.lookup = { exam, key in RecoveryFixture.receipt(exam, key, state: "pending") }
        f.clock.date = try XCTUnwrap(f.upload.nextAttemptAt)
        await f.queue.processQueue()
        XCTAssertEqual(f.events.sends, 1)
        XCTAssertEqual(f.events.lookups, 1)
        XCTAssertEqual(f.upload.retryCount, 0)
        XCTAssertGreaterThan(try XCTUnwrap(f.upload.nextAttemptAt), f.clock.date)
        XCTAssertTrue(f.events.accepted.isEmpty)
    }

    @MainActor
    func testBusyResponseHonorsPersistedRetryAfterAndDoesNotBurnBudget() async throws {
        let f = try await fixture()
        defer { f.cleanup() }
        let deadline = f.clock.date.addingTimeInterval(120)
        f.interactor.submit = { _, _ in throw UploadHTTPFailure(statusCode: 503, retryAfter: deadline, underlying: .networkError("busy")) }
        await f.queue.processQueue()
        XCTAssertEqual(f.upload.nextAttemptAt, deadline)
        XCTAssertEqual(f.upload.retryCount, 0)
        for _ in 0..<10 { await f.queue.processQueue() }
        XCTAssertEqual(f.events.sends, 1)
        XCTAssertEqual(f.events.lookups, 0)
        f.interactor.lookup = { exam, key in RecoveryFixture.receipt(exam, key, state: "retryable") }
        f.clock.date = deadline
        await f.queue.processQueue()
        XCTAssertEqual(f.events.order, ["send", "lookup", "send"])
        XCTAssertEqual(f.events.sentKeys.count, 2)
        XCTAssertEqual(f.events.sentKeys.first, f.events.sentKeys.last)
        XCTAssertEqual(f.upload.retryCount, 0)
    }

    @MainActor
    func testRetryDeadlinePersistsAcrossQueueRecreation() async throws {
        let f = try await fixture()
        defer { f.cleanup() }
        let deadline = f.clock.date.addingTimeInterval(600)
        f.interactor.submit = { _, _ in throw UploadHTTPFailure(statusCode: 429, retryAfter: deadline, underlying: .networkError("busy")) }
        await f.queue.processQueue()
        let context = ModelContext(f.context.container)
        let persisted = try XCTUnwrap(context.fetch(FetchDescriptor<PendingUpload>()).first)
        XCTAssertEqual(persisted.nextAttemptAt, deadline)
        XCTAssertEqual(persisted.submissionId, f.upload.submissionId)
        let next = VideoUploadQueueService(sessionProvider: { f.session }, now: { f.clock.date }, onAccepted: { _ in XCTFail("Too early") })
        next.configure(modelContext: context, examInteractor: f.interactor, networkRetryManager: f.network)
        await next.processQueue()
        XCTAssertEqual(f.events.sends, 1)
        XCTAssertEqual(f.events.lookups, 0)
    }

    @MainActor
    func testPermanentVideoRejectionStopsAutomaticRetriesAndKeepsFile() async throws {
        let f = try await fixture()
        defer { f.cleanup() }
        f.interactor.submit = { _, _ in throw UploadHTTPFailure(statusCode: 413, retryAfter: nil, underlying: .networkError("large")) }
        await f.queue.processQueue()
        for _ in 0..<3 { await f.queue.processQueue() }
        XCTAssertEqual(f.events.sends, 1)
        XCTAssertEqual(f.upload.stopReason, .replaceVideo)
        XCTAssertTrue(f.queue.requiresReplacementVideo(for: "exam"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: f.upload.localFilePath))
        XCTAssertNil(f.upload.nextAttemptAt)
    }

    @MainActor
    func testAuthenticationFailurePausesWithoutConsumingRetryBudget() async throws {
        let f = try await fixture()
        defer { f.cleanup() }
        f.upload.retryCount = 2
        f.interactor.submit = { _, _ in throw NetworkError.unauthorized() }
        await f.queue.processQueue()
        await f.queue.processQueue()
        XCTAssertEqual(f.events.sends, 1)
        XCTAssertEqual(f.upload.retryCount, 2)
        XCTAssertEqual(f.upload.stopReason, .authentication)
        XCTAssertTrue(FileManager.default.fileExists(atPath: f.upload.localFilePath))
    }

    @MainActor
    func testUnavailableOrMismatchedReceiptNeverPermitsResend() async throws {
        for invalidIdentity in [false, true] {
            let f = try await fixture()
            defer { f.cleanup() }
            f.upload.needsReconciliation = true
            f.interactor.lookup = { exam, key in
                if invalidIdentity { return RecoveryFixture.receipt(exam, UUID().uuidString, state: "accepted") }
                throw UploadHTTPFailure(statusCode: 404, retryAfter: nil, underlying: .networkError("old server"))
            }
            await f.queue.processQueue()
            XCTAssertEqual(f.events.sends, 0)
            XCTAssertTrue(f.events.accepted.isEmpty)
            XCTAssertEqual(f.upload.stopReason, .serviceUpdate)
            XCTAssertTrue(FileManager.default.fileExists(atPath: f.upload.localFilePath))
        }
    }

    @MainActor
    func testConflictLooksUpExactReceiptAndStopsIfNoReceiptExists() async throws {
        let f = try await fixture()
        defer { f.cleanup() }
        f.interactor.submit = { _, _ in throw UploadHTTPFailure(statusCode: 409, retryAfter: nil, underlying: .networkError("conflict")) }
        await f.queue.processQueue()
        XCTAssertTrue(f.upload.hasSubmissionConflict)
        f.clock.date = try XCTUnwrap(f.upload.nextAttemptAt)
        await f.queue.processQueue()
        XCTAssertEqual(f.events.order, ["send", "lookup"])
        XCTAssertEqual(f.upload.stopReason, .permanent)
        XCTAssertTrue(f.events.accepted.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: f.upload.localFilePath))
    }

    @MainActor
    func testAuthoritativeNotFoundAllowsSameKeyResend() async throws {
        let f = try await fixture()
        defer { f.cleanup() }
        f.upload.needsReconciliation = true
        f.interactor.submit = { exam, key in RecoveryFixture.response(exam, key, state: "accepted", code: 201) }
        await f.queue.processQueue()
        XCTAssertEqual(f.events.order, ["lookup", "send"])
        XCTAssertEqual(f.events.accepted, ["exam"])
    }

    @MainActor
    func testChangedLocalBytesNeverReuseOriginalSubmissionKey() async throws {
        let f = try await fixture()
        defer { f.cleanup() }
        try Data("corrupted or replaced externally".utf8).write(to: URL(fileURLWithPath: f.upload.localFilePath))
        await f.queue.processQueue()
        XCTAssertEqual(f.events.sends, 0)
        XCTAssertEqual(f.upload.stopReason, .replaceVideo)
    }

    @MainActor
    func testReplacementDuringSuspendedReceiptCannotDeleteNewVideo() async throws {
        for returnsFailure in [false, true] {
            let f = try await fixture()
            defer { f.cleanup() }
            f.upload.needsReconciliation = true
            let gate = RecoveryGate()
            let started = expectation(description: "Old receipt lookup suspended")
            f.interactor.lookup = { exam, key in
                started.fulfill()
                await gate.wait()
                if returnsFailure {
                    throw UploadHTTPFailure(statusCode: 403, retryAfter: nil, underlying: .networkError("old rejection"))
                }
                return RecoveryFixture.receipt(exam, key, state: "accepted")
            }
            let worker = Task { await f.queue.processQueue() }
            await fulfillment(of: [started], timeout: 2)
            f.network.isConnected = false
            try Data("new video B".utf8).write(to: f.source)
            try await f.queue.enqueue(examinationId: "exam", patientId: "patient", slideId: "slide", sourceURL: f.source)
            let newKey = f.upload.submissionId
            let newPath = f.upload.localFilePath
            let newHash = f.upload.videoSHA256
            await gate.open()
            await worker.value

            XCTAssertEqual(try f.context.fetchCount(FetchDescriptor<PendingUpload>()), 1)
            XCTAssertEqual(f.upload.submissionId, newKey)
            XCTAssertEqual(f.upload.localFilePath, newPath)
            XCTAssertEqual(f.upload.videoSHA256, newHash)
            XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: newPath)), Data("new video B".utf8))
            XCTAssertEqual(f.upload.state, .pending)
            XCTAssertNil(f.upload.stopReason)
            XCTAssertNil(f.upload.lastError)
            XCTAssertNil(f.upload.nextAttemptAt)
            XCTAssertEqual(f.upload.retryCount, 0)
            XCTAssertFalse(f.upload.needsReconciliation)
            XCTAssertTrue(f.events.accepted.isEmpty)
            XCTAssertEqual(f.events.sends, 0)
        }
    }

    @MainActor
    func testReplacementDuringSuspendedHashCannotSendOrPoisonNewVideo() async throws {
        let started = expectation(description: "Old file hash suspended")
        let gate = RecoveryGate()
        var pauseNextHash = false
        let f = try RecoveryFixture(hashVideo: { url in
            let digest = try await VideoUploadQueueService.sha256(of: url)
            if pauseNextHash {
                pauseNextHash = false
                started.fulfill()
                await gate.wait()
            }
            return digest
        })
        defer { f.cleanup() }
        try await f.queue.enqueue(examinationId: "exam", patientId: "patient", slideId: "slide", sourceURL: f.source)
        f.upload = try XCTUnwrap(f.context.fetch(FetchDescriptor<PendingUpload>()).first)
        f.network.isConnected = true
        pauseNextHash = true
        let worker = Task { await f.queue.processQueue() }
        await fulfillment(of: [started], timeout: 2)
        f.network.isConnected = false
        try Data("new hash video B".utf8).write(to: f.source)
        try await f.queue.enqueue(examinationId: "exam", patientId: "patient", slideId: "slide", sourceURL: f.source)
        let key = f.upload.submissionId
        let hash = f.upload.videoSHA256
        await gate.open()
        await worker.value
        XCTAssertEqual(f.events.sends, 0)
        XCTAssertEqual(f.upload.submissionId, key)
        XCTAssertEqual(f.upload.videoSHA256, hash)
        XCTAssertNil(f.upload.stopReason)
        XCTAssertNil(f.upload.lastError)
        XCTAssertFalse(f.upload.needsReconciliation)
        XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: f.upload.localFilePath)), Data("new hash video B".utf8))
    }

    func testRetryAfterParsesSecondsAndHTTPDateWithBoundedValues() {
        let now = Date(timeIntervalSince1970: 0)
        XCTAssertEqual(UploadHTTPFailure.retryDate("120", now: now), now.addingTimeInterval(120))
        XCTAssertEqual(UploadHTTPFailure.retryDate("Thu, 01 Jan 1970 00:02:00 GMT", now: now), now.addingTimeInterval(120))
        XCTAssertNil(UploadHTTPFailure.retryDate("invalid", now: now))
        XCTAssertNil(UploadHTTPFailure.retryDate("-1", now: now))
        XCTAssertEqual(UploadHTTPFailure.retryDate("999999999", now: now), now.addingTimeInterval(86400))
    }

    func testQueuedInteractorSendsStableIdentityAndChecksumThroughOriginalEntrypoint() async throws {
        let network = RecoveryHeaderNetwork()
        let interactor = ExamInteractor(networkService: network)
        let key = UUID().uuidString.lowercased()
        let hash = String(repeating: "a", count: 64)
        let response = try await interactor.submitQueuedExamination(
            videoFileURL: URL(fileURLWithPath: "/not-read-by-stub.mp4"), examinationId: "exam", patientId: "patient",
            submissionId: key, videoSHA256: hash
        )
        XCTAssertEqual(network.headers?["Idempotency-Key"], key)
        XCTAssertEqual(network.headers?["X-Video-SHA256"], hash)
        XCTAssertEqual(response.data.submissionId, key)
        XCTAssertEqual(response.data.submissionReceiptVersion, 1)
    }

    func testTransportMetadataIsTypedOnlyForQueueContext() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RecoveryURLProtocol.self]
        let service = AlamofireNetworkService(session: Session(configuration: configuration))
        let endpoint = "https://example.invalid/user/login"
        do {
            let _: APIResponse<RecoveryEmpty> = try await service.get(urlString: endpoint, headers: nil)
            XCTFail("Expected original generic error")
        } catch NetworkError.networkError(let message, _) {
            XCTAssertEqual(message, "Server error (503)")
        }
        let started = Date()
        do {
            let _: APIResponse<RecoveryEmpty> = try await UploadRequestContext.$preservesHTTPMetadata.withValue(true) {
                try await service.get(urlString: endpoint, headers: nil)
            }
            XCTFail("Expected typed upload status")
        } catch let failure as UploadHTTPFailure {
            XCTAssertEqual(failure.statusCode, 503)
            let retryAt = try XCTUnwrap(failure.retryAfter)
            XCTAssertGreaterThanOrEqual(retryAt, started.addingTimeInterval(120))
            XCTAssertLessThan(retryAt, Date().addingTimeInterval(121))
        }
    }

    func testEmptyRejectionBodiesPreserveStatusAndRetryAfter() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RecoveryURLProtocol.self]
        let service = AlamofireNetworkService(session: Session(configuration: configuration))
        for status in [413, 429] {
            let started = Date()
            do {
                let _: APIResponse<RecoveryEmpty> = try await UploadRequestContext.$preservesHTTPMetadata.withValue(true) {
                    try await service.get(urlString: "https://example.invalid/user/login/empty-\(status)", headers: nil)
                }
                XCTFail("An empty rejection body must still carry typed status")
            } catch let failure as UploadHTTPFailure {
                XCTAssertEqual(failure.statusCode, status)
                XCTAssertGreaterThanOrEqual(try XCTUnwrap(failure.retryAfter), started.addingTimeInterval(120))
            }
        }
    }

    func testConnectionLossAfterHTTPHeadersRemainsAmbiguousTransportError() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RecoveryURLProtocol.self]
        let service = AlamofireNetworkService(session: Session(configuration: configuration))
        do {
            let _: APIResponse<RecoveryEmpty> = try await UploadRequestContext.$preservesHTTPMetadata.withValue(true) {
                try await service.get(urlString: "https://example.invalid/user/login/transport-failure", headers: nil)
            }
            XCTFail("Connection failure must not become definite HTTP rejection")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .networkConnectionLost)
        }
    }

    func testExistingReceiptStatesRequireValidAttemptIdentity() {
        for state in ["pending", "retryable", "accepted"] {
            for attempt in [nil, "invalid"] as [String?] {
                let receipt = AnalysisSubmissionReceipt(submissionId: "key", examinationId: "exam", state: state,
                                                        attemptId: attempt, submissionReceiptVersion: 1)
                XCTAssertFalse(receipt.matches(examinationId: "exam", submissionId: "key"))
            }
        }
        XCTAssertTrue(AnalysisSubmissionReceipt(submissionId: "key", examinationId: "exam", state: "not_found",
                                                attemptId: nil, submissionReceiptVersion: 1)
            .matches(examinationId: "exam", submissionId: "key"))
    }
}

private struct RecoveryEmpty: Decodable {}

private final class RecoveryURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let path = request.url!.lastPathComponent
        let status = path == "empty-413" ? 413 : (path == "empty-429" ? 429 : 503)
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json", "Retry-After": "120"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if path == "transport-failure" {
            client?.urlProtocol(self, didFailWithError: URLError(.networkConnectionLost))
            return
        }
        if !path.hasPrefix("empty-") { client?.urlProtocol(self, didLoad: Data("{}".utf8)) }
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

private final class RecoveryHeaderNetwork: MockNetworkService {
    var headers: [String: String]?
    override func multipartFile<T: Decodable>(urlString: String, headers: [String: String]?, fileURL: URL,
                                              fieldName: String, fileName: String?, mimeType: String?) async throws -> APIResponse<T> {
        self.headers = headers
        let body: [String: Any] = ["status": "success", "code": 201, "message": "accepted", "data": [
            "submissionId": headers?["Idempotency-Key"] ?? "", "examinationId": "exam",
            "attemptId": UUID().uuidString, "state": "accepted", "submissionReceiptVersion": 1,
            "statusExamination": "INPROGRESS"
        ]]
        return try JSONDecoder().decode(APIResponse<T>.self, from: JSONSerialization.data(withJSONObject: body))
    }
}

@MainActor
private final class RecoveryFixture {
    let context: ModelContext
    let network = NetworkRetryManager(monitorsConnectivity: false)
    let interactor = RecoveryInteractor()
    let clock = RecoveryClock()
    let events = RecoveryEvents()
    let session = UploadQueueSession(ownerUserId: "recovery-owner", generation: UUID())
    let source = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
    let queue: VideoUploadQueueService
    var upload: PendingUpload!

    init(hashVideo: @escaping @MainActor (URL) async throws -> String = { try await VideoUploadQueueService.sha256(of: $0) }) throws {
        let schema = Schema([PendingUpload.self])
        context = ModelContext(try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]))
        let clock = clock, events = events, session = session
        queue = VideoUploadQueueService(sessionProvider: { session }, now: { clock.date }, onAccepted: { events.accepted.append($0) }, hashVideo: hashVideo)
        interactor.events = events
        interactor.submit = { _, _ in throw CancellationError() }
        interactor.lookup = { exam, key in Self.receipt(exam, key, state: "not_found") }
        network.isConnected = false
        queue.configure(modelContext: context, examInteractor: interactor, networkRetryManager: network)
        try Data("video".utf8).write(to: source)
    }

    func cleanup() {
        network.isConnected = false
        try? FileManager.default.removeItem(at: source)
        if let upload { try? FileManager.default.removeItem(atPath: upload.localFilePath) }
    }

    static func receipt(_ exam: String, _ key: String, state: String) -> AnalysisSubmissionReceipt {
        AnalysisSubmissionReceipt(submissionId: key, examinationId: exam, state: state,
                                  attemptId: UUID().uuidString, submissionReceiptVersion: 1)
    }

    static func response(_ exam: String, _ key: String, state: String, code: Int) -> APIResponse<ForwardVideoToMLData> {
        APIResponse(status: "success", code: code, message: "receipt", data: ForwardVideoToMLData(
            examinationId: exam, statusExamination: .INPROGRESS, statusML: nil,
            submissionId: key, attemptId: UUID().uuidString, state: state, submissionReceiptVersion: 1
        ))
    }
}

private actor RecoveryGate {
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

@MainActor private final class RecoveryClock { var date = Date(timeIntervalSince1970: 1_800_000_000) }
@MainActor private final class RecoveryEvents {
    var sends = 0
    var lookups = 0
    var accepted: [String] = []
    var order: [String] = []
    var sentKeys: [String] = []
}

private final class RecoveryInteractor: ExamInteractor {
    var events: RecoveryEvents!
    var submit: (@MainActor (String, String) async throws -> APIResponse<ForwardVideoToMLData>)!
    var lookup: (@MainActor (String, String) async throws -> AnalysisSubmissionReceipt)!
    init() { super.init(networkService: MockNetworkService()) }
    override func submitQueuedExamination(videoFileURL: URL, examinationId: String, patientId: String,
                                         submissionId: String, videoSHA256: String) async throws -> APIResponse<ForwardVideoToMLData> {
        await MainActor.run {
            events.sends += 1
            events.order.append("send")
            events.sentKeys.append(submissionId)
        }
        return try await submit(examinationId, submissionId)
    }
    override func fetchSubmissionReceipt(examinationId: String, submissionId: String) async throws -> AnalysisSubmissionReceipt {
        await MainActor.run {
            events.lookups += 1
            events.order.append("lookup")
        }
        return try await lookup(examinationId, submissionId)
    }
}
