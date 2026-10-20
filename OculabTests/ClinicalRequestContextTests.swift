import Alamofire
import XCTest
@testable import Oculab

final class ClinicalRequestContextTests: XCTestCase {
    @MainActor
    private func withFixture(_ body: (AlamofireNetworkService, ClinicalHTTPRequests) async throws -> Void) async throws {
        let keys: [KeychainKey] = [.accessToken, .refreshToken, .accessPin]
        let previous = keys.map { ($0, KeychainHelper.string(for: $0)) }
        let defaults = UserDefaultType.allCases.map { ($0, UserDefaults.standard.object(forKey: $0.rawValue)) }
        let tracking = ["tracked_analysis_examination_ids", "pending_resume_analysis_examination_id"].map { ($0, UserDefaults.standard.object(forKey: $0)) }
        defer {
            ClinicalURLProtocol.handler = nil
            AuthSessionManager.beginSessionChange()
            for (key, value) in previous {
                if let value { KeychainHelper.set(value, for: key) } else { KeychainHelper.remove(key) }
            }
            for (key, value) in defaults { UserDefaults.standard.set(value, forKey: key.rawValue) }
            for (key, value) in tracking { UserDefaults.standard.set(value, forKey: key) }
            AuthSessionManager.completeSessionChange()
        }
        setSession("clinical-a")
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ClinicalURLProtocol.self]
        let service = AlamofireNetworkService(session: Session(configuration: configuration))
        try await body(service, ClinicalHTTPRequests())
    }

    @MainActor
    private func setSession(_ owner: String) {
        AuthSessionManager.beginSessionChange()
        UserDefaults.standard.set(owner, forKey: UserDefaultType.userId.rawValue)
        UserDefaults.standard.set(true, forKey: UserDefaultType.isUserLoggedIn.rawValue)
        KeychainHelper.set(owner + "-token", for: .accessToken)
        KeychainHelper.set(owner + "-refresh", for: .refreshToken)
        AuthSessionManager.completeSessionChange()
    }

    @MainActor
    func testQueuedClinicalMutationsDoNotResolveNewAccountTokenOrSendHTTP() async throws {
        for operation in QueuedClinicalMutation.allCases {
            try await withFixture { service, requests in
                ClinicalURLProtocol.handler = { request in
                    requests.hold(request)
                    request.respond(status: 200, body: ClinicalHTTPRequests.success)
                }
                let started = expectation(description: "Clinical request queued before Alamofire")
                let gate = ClinicalContextGate()
                let network = QueuedClinicalNetwork(service: service) {
                    started.fulfill()
                    await gate.wait()
                }
                let pending = Task { try await operation.perform(network: network) }
                await fulfillment(of: [started], timeout: 5)
                XCTAssertEqual(network.capturedSession?.ownerUserId, "clinical-a", "Interactors must propagate their captured session across the network executor hop")
                setSession("clinical-b")
                await gate.open()
                do { try await pending.value; XCTFail("The queued A operation must be cancelled before B's token is resolved") }
                catch is CancellationError {}
                XCTAssertEqual(requests.count, 0, "A stale clinical context must not create an HTTP request")
                XCTAssertEqual(KeychainHelper.string(for: .accessToken), "clinical-b-token")
            }
        }
    }

    @MainActor
    func testSuccessfulClinicalHTTPResponseIsDiscardedAfterAccountSwitch() async throws {
        try await withFixture { service, requests in
            let expected = try XCTUnwrap(AuthSessionManager.uploadQueueSession)
            let started = expectation(description: "Authenticated clinical request in flight")
            ClinicalURLProtocol.handler = { request in requests.hold(request); started.fulfill() }
            let pending = Task {
                try await ClinicalRequestContext.withSession(expected) {
                    let _: APIResponse<ClinicalContextPayload> = try await service.get(urlString: API.BE + "/patient/clinical-context-test", headers: nil)
                }
            }
            await fulfillment(of: [started], timeout: 5)
            XCTAssertEqual(requests.authorization, "Bearer clinical-a-token")
            setSession("clinical-b")
            requests.release(status: 200, body: ClinicalHTTPRequests.success)
            do { try await pending.value; XCTFail("A successful old-session response must not escape the network boundary") }
            catch is CancellationError {}
            XCTAssertEqual(requests.count, 1)
            XCTAssertEqual(KeychainHelper.string(for: .accessToken), "clinical-b-token")
        }
    }

    @MainActor
    func testScopedClinicalRequestCanRefreshTokenWithinSameSession() async throws {
        try await withFixture { service, requests in
            let expected = try XCTUnwrap(AuthSessionManager.uploadQueueSession)
            ClinicalURLProtocol.handler = { request in
                requests.hold(request)
                if request.request.url!.path.contains("refresh-token") {
                    request.respond(status: 200, body: #"{"status":"success","code":200,"message":"OK","data":{"accessToken":"clinical-a-fresh","refreshToken":"clinical-a-refresh-fresh"}}"#)
                } else if request.request.value(forHTTPHeaderField: "Authorization") == "Bearer clinical-a-fresh" {
                    request.respond(status: 200, body: ClinicalHTTPRequests.success)
                } else {
                    request.respond(status: 401, body: "{}")
                }
            }
            let response: APIResponse<ClinicalContextPayload> = try await ClinicalRequestContext.withSession(expected) {
                try await service.get(urlString: API.BE + "/patient/clinical-context-test", headers: ["X-Clinical-Test": "preserved"])
            }
            XCTAssertEqual(response.data.value, "safe")
            XCTAssertEqual(requests.count, 3)
            XCTAssertEqual(KeychainHelper.string(for: .accessToken), "clinical-a-fresh")
            XCTAssertEqual(AuthSessionManager.uploadQueueSession, expected)
        }
    }
}

private struct ClinicalContextPayload: Decodable { let value: String }

private enum QueuedClinicalMutation: CaseIterable {
    case directoryCreate, directoryUpdate, wizardCreate, wizardExamination
    @MainActor
    func perform(network: NetworkServiceProtocol) async throws {
        let patient = Patient(id: "patient-a", name: "Siti", DoB: Date(timeIntervalSince1970: 0), sex: .FEMALE)
        switch self {
        case .directoryCreate: _ = try await PatientInteractor(networkService: network).addNewPatient(patient: patient)
        case .directoryUpdate: _ = try await PatientInteractor(networkService: network).updatePatient(patient: patient, patientId: patient.id)
        case .wizardCreate: _ = try await InputPatientInteractor(networkService: network).addNewPatient(patient: patient)
        case .wizardExamination: _ = try await InputPatientInteractor(networkService: network).addNewExamination(patientId: patient.id, examinations: [])
        }
    }
}

/// Models a real executor delay between the interactor's captured session and
/// Alamofire's authorization resolution, then delegates to actual HTTP handling.
private final class QueuedClinicalNetwork: MockNetworkService {
    let service: AlamofireNetworkService
    let beforeRequest: @MainActor () async -> Void
    @MainActor private(set) var capturedSession: UploadQueueSession?
    init(service: AlamofireNetworkService, beforeRequest: @escaping @MainActor () async -> Void) {
        self.service = service
        self.beforeRequest = beforeRequest
    }
    override func post<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B) async throws -> APIResponse<T> {
        await MainActor.run { capturedSession = ClinicalRequestContext.expectedSession }
        await beforeRequest()
        return try await service.post(urlString: urlString, headers: headers, body: body)
    }
    override func update<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B) async throws -> APIResponse<T> {
        await MainActor.run { capturedSession = ClinicalRequestContext.expectedSession }
        await beforeRequest()
        return try await service.update(urlString: urlString, headers: headers, body: body)
    }
}

private final class ClinicalHTTPRequests: @unchecked Sendable {
    static let success = #"{"status":"success","code":200,"message":"OK","data":{"value":"safe"}}"#
    private let lock = NSLock()
    private var pending: ClinicalURLProtocol?
    private var total = 0
    private var token: String?
    var count: Int { lock.lock(); defer { lock.unlock() }; return total }
    var authorization: String? { lock.lock(); defer { lock.unlock() }; return token }
    func hold(_ request: ClinicalURLProtocol) {
        lock.lock()
        total += 1
        token = request.request.value(forHTTPHeaderField: "Authorization")
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

private final class ClinicalURLProtocol: URLProtocol {
    static var handler: ((ClinicalURLProtocol) -> Void)?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() { Self.handler?(self) }
    override func stopLoading() {}
    func respond(status: Int, body: String) {
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
}

private actor ClinicalContextGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var isOpen = false
    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { continuation = $0 }
    }
    func open() { isOpen = true; continuation?.resume(); continuation = nil }
}
