import XCTest
@testable import Oculab

final class TaskAssignmentSessionContractTests: XCTestCase {
    @MainActor
    private func withFixture(_ body: (TaskSessionNetwork, InputPatientInteractor) async throws -> Void) async throws {
        let keys: [KeychainKey] = [.accessToken, .refreshToken, .accessPin]
        let saved = keys.map { ($0, KeychainHelper.string(for: $0)) }
        let defaults = UserDefaultType.allCases.map { ($0, UserDefaults.standard.object(forKey: $0.rawValue)) }
        let tracking = ["tracked_analysis_examination_ids", "pending_resume_analysis_examination_id"].map { ($0, UserDefaults.standard.object(forKey: $0)) }
        defer {
            AuthSessionManager.beginSessionChange()
            for (key, value) in saved {
                if let value { KeychainHelper.set(value, for: key) } else { KeychainHelper.remove(key) }
            }
            for (key, value) in defaults { UserDefaults.standard.set(value, forKey: key.rawValue) }
            for (key, value) in tracking { UserDefaults.standard.set(value, forKey: key) }
            AuthSessionManager.completeSessionChange()
        }
        setSession("wizard-owner-a")
        let network = TaskSessionNetwork()
        try await body(network, InputPatientInteractor(networkService: network))
    }

    @MainActor
    private func setSession(_ id: String) {
        AuthSessionManager.beginSessionChange()
        UserDefaults.standard.set(id, forKey: UserDefaultType.userId.rawValue)
        UserDefaults.standard.set(true, forKey: UserDefaultType.isUserLoggedIn.rawValue)
        KeychainHelper.set(id + "-token", for: .accessToken)
        AuthSessionManager.completeSessionChange()
    }

    @MainActor
    func testAllWizardNetworkBoundariesRejectOldAccountResponsesAfterSwitchAndLogout() async throws {
        for operation in TaskSessionOperation.allCases {
            for logout in [false, true] {
                try await withFixture { network, interactor in
                    let started = expectation(description: "\(operation) held")
                    let gate = TaskSessionGate()
                    network.response = { request in
                        started.fulfill()
                        await gate.wait()
                        return try TaskSessionNetwork.payload(for: request.path)
                    }
                    let pending = Task { try await operation.perform(interactor) }
                    await fulfillment(of: [started], timeout: 5)
                    if logout { AuthSessionManager.invalidateSession() } else { setSession("wizard-owner-b") }
                    await gate.open()
                    do { try await pending.value; XCTFail("A previous session's response must be rejected") }
                    catch is CancellationError {}
                    XCTAssertEqual(network.requests.count, 1)
                    XCTAssertEqual(network.requests.first?.headers?["Authorization"], "Bearer wizard-owner-a-token")
                    XCTAssertEqual(AuthSessionManager.uploadQueueSession?.ownerUserId, logout ? nil : "wizard-owner-b")
                }
            }
        }
    }

    @MainActor
    func testWizardOwnerScopedEndpointsUseCapturedAuthenticatedOwner() async throws {
        try await withFixture { network, interactor in
            _ = try await interactor.getAllUser()
            _ = try await interactor.getAllPatient()
            _ = try await interactor.addNewPatient(patient: Patient(name: "Siti", DoB: Date(timeIntervalSince1970: 0), sex: .FEMALE))
            XCTAssertEqual(network.requests.map(\.path), [
                "/user/get-all-pics/wizard-owner-a", "/patient/get-all-patients/wizard-owner-a", "/patient/create-new-patient/wizard-owner-a"
            ])
            XCTAssertTrue(network.requests.allSatisfy { $0.headers?["Authorization"] == "Bearer wizard-owner-a-token" })
            let request = try XCTUnwrap(network.requests.last?.body)
            let body = try XCTUnwrap(JSONSerialization.jsonObject(with: request) as? [String: Any])
            XCTAssertEqual(body["NIK"] as? String, "")
        }
    }

    @MainActor
    func testWizardPatientAndUserLookupsRejectWrongIdentities() async throws {
        for userLookup in [false, true] {
            try await withFixture { network, interactor in
                let object: [String: Any]
                if userLookup { object = ["id": "different-user", "name": "Other", "role": "LAB"] }
                else { object = TaskSessionNetwork.patient(id: "different-patient") }
                let response = try TaskSessionNetwork.envelope(object)
                network.response = { _ in response }
                do {
                    if userLookup { _ = try await interactor.getUserById(userId: "pic-a") }
                    else { _ = try await interactor.getPatientById(patientId: "patient-a") }
                    XCTFail("A lookup may not silently change the selected clinical identity")
                } catch let error as URLError { XCTAssertEqual(error.code, .cannotParseResponse) }
            }
        }
    }

    @MainActor
    func testLoggedOutWizardDoesNotStartAnyClinicalRequest() async throws {
        try await withFixture { network, interactor in
            AuthSessionManager.invalidateSession()
            for operation in TaskSessionOperation.allCases {
                do { try await operation.perform(interactor); XCTFail("Logged out operation must fail") }
                catch let error as URLError { XCTAssertEqual(error.code, .userAuthenticationRequired) }
            }
            XCTAssertTrue(network.requests.isEmpty)
        }
    }
}

private enum TaskSessionOperation: CaseIterable {
    case pics, patients, patient, pic, createPatient, createExamination
    @MainActor
    func perform(_ interactor: InputPatientInteractor) async throws {
        switch self {
        case .pics: _ = try await interactor.getAllUser()
        case .patients: _ = try await interactor.getAllPatient()
        case .patient: _ = try await interactor.getPatientById(patientId: "patient-a")
        case .pic: _ = try await interactor.getUserById(userId: "pic-a")
        case .createPatient: _ = try await interactor.addNewPatient(patient: Patient(name: "Siti", DoB: Date(timeIntervalSince1970: 0), sex: .FEMALE))
        case .createExamination: _ = try await interactor.addNewExamination(patientId: "patient-a", examinations: [])
        }
    }
}

private final class TaskSessionNetwork: MockNetworkService {
    struct Request { let path: String; let headers: [String: String]?; let body: Data? }
    @MainActor private(set) var requests: [Request] = []
    var response: @MainActor (Request) async throws -> Data = { try TaskSessionNetwork.payload(for: $0.path) }
    override func get<T: Decodable>(urlString: String, headers: [String: String]?) async throws -> APIResponse<T> {
        try await execute(url: urlString, headers: headers, body: nil)
    }
    override func post<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B) async throws -> APIResponse<T> {
        try await execute(url: urlString, headers: headers, body: JSONEncoder().encode(body))
    }
    private func execute<T: Decodable>(url: String, headers: [String: String]?, body: Data?) async throws -> APIResponse<T> {
        let request = Request(path: URL(string: url)!.path, headers: headers, body: body)
        await MainActor.run { requests.append(request) }
        return try JSONDecoder().decode(APIResponse<T>.self, from: try await response(request))
    }
    static func patient(id: String = "patient-a") -> [String: Any] {
        ["id": id, "name": "Siti", "NIK": "", "DoB": "1990-02-18", "sex": "FEMALE"]
    }
    static func envelope(_ value: Any) throws -> Data {
        try JSONSerialization.data(withJSONObject: ["status": "success", "code": 200, "message": "OK", "data": value])
    }
    static func payload(for path: String) throws -> Data {
        if path.contains("get-all-pics") { return try envelope([["id": "pic-a", "name": "Officer", "role": "LAB"]]) }
        if path.contains("get-user-data") { return try envelope(["id": "pic-a", "name": "Officer", "role": "LAB"]) }
        if path.contains("get-all-patients") { return try envelope([patient()]) }
        if path.contains("create-examination") { return try envelope([]) }
        return try envelope(patient())
    }
}

private actor TaskSessionGate {
    private var continuations: [CheckedContinuation<Void, Never>] = []
    private var isOpen = false
    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { continuations.append($0) }
    }
    func open() { isOpen = true; continuations.forEach { $0.resume() }; continuations.removeAll() }
}
