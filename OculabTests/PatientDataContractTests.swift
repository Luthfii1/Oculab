import XCTest
@testable import Oculab

final class PatientDataContractTests: XCTestCase {
    func testPatientDecodesOptionalIdentifiersAndDateOnlyWithoutInventingBirthDate() throws {
        let identifiers: [Any] = [NSNull(), ""]
        for nik in identifiers {
            let patient = try JSONDecoder().decode(Patient.self, from: JSONSerialization.data(withJSONObject: [
                "id": "patient-a", "name": "Sari", "NIK": nik, "sex": "FEMALE", "medicalRecordNumber": "000042"
            ]))
            XCTAssertEqual(patient.NIK, "")
            XCTAssertNil(patient.DoB)
            XCTAssertEqual(patient.medicalRecordNumber, "000042")
        }
        let patient = try JSONDecoder().decode(Patient.self, from: PatientContractNetwork.patientData())
        XCTAssertEqual(PatientBirthDateCoding.encode(try XCTUnwrap(patient.DoB)), "1990-02-18")
    }

    func testNewBirthDatesRoundTripAsCalendarDatesAcrossIndonesianAndOtherTimeZones() throws {
        for zone in ["Asia/Jakarta", "Asia/Makassar", "Asia/Jayapura", "Asia/Tokyo", "America/Los_Angeles", "Pacific/Kiritimati"] {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = try XCTUnwrap(TimeZone(identifier: zone))
            let selected = try XCTUnwrap(calendar.date(from: DateComponents(year: 2000, month: 2, day: 29, hour: 12)))
            let wire = PatientBirthDateCoding.encode(selected, calendar: calendar)
            XCTAssertEqual(wire, "2000-02-29", zone)
            for response in [wire, wire + "T00:00:00.000Z", wire + "T00:00:00Z"] {
                let decoded = try XCTUnwrap(PatientBirthDateCoding.decode(response, calendar: calendar))
                XCTAssertEqual(PatientBirthDateCoding.encode(decoded, calendar: calendar), wire, zone)
            }
        }
    }

    func testLegacyBirthTimestampIsPreservedAcrossUnrelatedEditsButChangedDateUsesCivilFormat() throws {
        let raw = "1990-02-18T17:23:45.123Z"
        let original = try JSONDecoder().decode(Patient.self, from: PatientContractNetwork.patientData(birthDate: raw))
        XCTAssertEqual(original.DoB, PatientBirthDateCoding.decodeInstant(raw))
        let edit = Patient(id: original.id, name: "Updated name", DoB: original.DoB, sex: original.sex, medicalRecordNumber: "RM-42")
        edit.preserveBirthDateEncoding(from: original)
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(edit)) as? [String: Any])
        XCTAssertEqual(payload["DoB"] as? String, raw)
        edit.DoB = Calendar.current.date(byAdding: .day, value: 1, to: try XCTUnwrap(edit.DoB))
        payload = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(edit)) as? [String: Any])
        XCTAssertEqual(payload["DoB"] as? String, PatientBirthDateCoding.encode(try XCTUnwrap(edit.DoB)))
        XCTAssertEqual((payload["DoB"] as? String)?.count, 10)
    }

    func testBirthDateParserRejectsInvalidCalendarDatesAndPreservesLegacyOffsetInstants() throws {
        for value in ["2025-02-29", "2026-02-30", "2026-13-01", "2026-01-00", "", "not-a-date"] {
            XCTAssertNil(PatientBirthDateCoding.decode(value), value)
        }
        let offset = "1990-02-18T23:00:00-01:00"
        XCTAssertEqual(PatientBirthDateCoding.decode(offset), PatientBirthDateCoding.decodeInstant(offset))
        XCTAssertNotNil(PatientBirthDateCoding.decode("1990-02-18T17:23:45Z"))
    }

    @MainActor
    func testReadinessDoesNotPublishValidationErrorsOrRequireOptionalIdentifiers() throws {
        let previous = ValidationManager.shared.errors
        defer { ValidationManager.shared.errors = previous }
        ValidationManager.shared.errors = ["existing-form": "Keep this"]
        let patient = Patient(name: "Sari", DoB: Date(timeIntervalSince1970: 0), sex: .FEMALE)
        for _ in 0..<20 { XCTAssertTrue(PatientIntakeValidation.isReady(patient: patient)) }
        XCTAssertEqual(ValidationManager.shared.errors, ["existing-form": "Keep this"])
        patient.NIK = "123"
        patient.BPJS = "１２３４５６７８９０１２３"
        patient.medicalRecordNumber = String(repeating: "A", count: 65)
        let errors = PatientIntakeValidation.errors(for: patient)
        XCTAssertNotNil(errors[.nik])
        XCTAssertNotNil(errors[.bpjs])
        XCTAssertNotNil(errors[.medicalRecordNumber])
        patient.NIK = ""
        patient.BPJS = nil
        patient.medicalRecordNumber = "000042"
        patient.DoB = nil
        patient.sex = .UNKNOWN
        XCTAssertEqual(Set(PatientIntakeValidation.errors(for: patient).keys), [.dateOfBirth, .sex])
    }

    func testFutureBirthDateUsesCalendarDayAndAcceptsTodayBeforeCurrentTime() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Jayapura"))
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 21, hour: 1)))
        let todayNoon = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 21, hour: 12)))
        let patient = Patient(name: "Sari", DoB: todayNoon, sex: .FEMALE)
        XCTAssertTrue(PatientIntakeValidation.isReady(patient: patient, now: now, calendar: calendar))
        patient.DoB = calendar.date(byAdding: .day, value: 1, to: todayNoon)
        XCTAssertNotNil(PatientIntakeValidation.errors(for: patient, now: now, calendar: calendar)[.dateOfBirth])
    }

    func testMalformedExaminationDatesAreNotReplacedWithToday() throws {
        for key in ["patientDob", "examinationDate"] {
            var data: [String: Any] = ["id": "exam-a", "slideId": "slide-a", "statusExamination": "FINISHED", "patientName": "Sari", "patientDob": "1990-02-18T00:00:00.000Z", "examinationDate": "2026-01-01T10:00:00.000Z"]
            data[key] = "invalid-date"
            XCTAssertThrowsError(try JSONDecoder().decode(ExaminationResultCardData.self, from: JSONSerialization.data(withJSONObject: data)))
        }
    }

    @MainActor
    func testUpdateExplicitlyClearsIdentifiersWhileCreateCanOmitOptionalIdentifiers() async throws {
        try await withNetwork { network, interactor in
            let patient = Patient(id: "patient-a", name: "Sari", DoB: PatientBirthDateCoding.decode("1990-02-18"), sex: .FEMALE)
            _ = try await interactor.updatePatient(patient: patient, patientId: patient.id)
            let update = try XCTUnwrap(network.requests.last?.body)
            let updateJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: update) as? [String: Any])
            XCTAssertTrue(updateJSON["BPJS"] is NSNull)
            XCTAssertTrue(updateJSON["medicalRecordNumber"] is NSNull)
            XCTAssertEqual(updateJSON["NIK"] as? String, "")
            XCTAssertEqual(updateJSON["DoB"] as? String, "1990-02-18")
            _ = try await interactor.addNewPatient(patient: patient)
            let create = try XCTUnwrap(network.requests.last?.body)
            let createJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: create) as? [String: Any])
            XCTAssertNil(createJSON["BPJS"])
            XCTAssertNil(createJSON["medicalRecordNumber"])
        }
    }

    @MainActor
    func testInteractorRejectsMismatchedPatientResponse() async throws {
        try await withNetwork { network, interactor in
            network.response = { _ in try PatientContractNetwork.envelope(PatientContractNetwork.patientObject(id: "different")) }
            do { _ = try await interactor.getPatientById(patientId: "patient-a"); XCTFail("Mismatched identity must be rejected") }
            catch let error as URLError { XCTAssertEqual(error.code, .cannotParseResponse) }
        }
    }

    @MainActor
    func testPatientRequestsRejectLateResponsesAfterAccountChangeOrLogout() async throws {
        for operation in PatientContractOperation.allCases {
            for logout in [false, true] {
                try await withNetwork { network, interactor in
                    let started = expectation(description: "\(operation) request held")
                    let gate = PatientContractGate()
                    network.response = { request in
                        started.fulfill()
                        await gate.wait()
                        return try PatientContractNetwork.response(for: request.path)
                    }
                    let pending = Task { try await operation.perform(interactor: interactor) }
                    await fulfillment(of: [started], timeout: 5)
                    if logout { AuthSessionManager.invalidateSession() } else { Self.setSession("contract-owner-b") }
                    await gate.open()
                    do { try await pending.value; XCTFail("Old session response must be rejected") }
                    catch is CancellationError {}
                    XCTAssertEqual(AuthSessionManager.uploadQueueSession?.ownerUserId, logout ? nil : "contract-owner-b")
                    XCTAssertEqual(KeychainHelper.string(for: .accessToken), logout ? nil : "contract-owner-b-token")
                }
            }
        }
    }

    @MainActor
    private func withNetwork(_ body: (PatientContractNetwork, PatientInteractor) async throws -> Void) async throws {
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
        Self.setSession("contract-owner-a")
        let network = PatientContractNetwork()
        try await body(network, PatientInteractor(networkService: network))
    }

    @MainActor
    private static func setSession(_ id: String) {
        AuthSessionManager.beginSessionChange()
        UserDefaults.standard.set(true, forKey: UserDefaultType.isUserLoggedIn.rawValue)
        UserDefaults.standard.set(id, forKey: UserDefaultType.userId.rawValue)
        KeychainHelper.set(id + "-token", for: .accessToken)
        AuthSessionManager.completeSessionChange()
    }
}

private enum PatientContractOperation: CaseIterable {
    case list, patient, examinations, create, update
    @MainActor
    func perform(interactor: PatientInteractor) async throws {
        let patient = Patient(id: "patient-a", name: "Sari", DoB: Date(timeIntervalSince1970: 0), sex: .FEMALE)
        switch self {
        case .list: _ = try await interactor.getAllPatient()
        case .patient: _ = try await interactor.getPatientById(patientId: patient.id)
        case .examinations: _ = try await interactor.getAllExamByPatientId(patientId: patient.id)
        case .create: _ = try await interactor.addNewPatient(patient: patient)
        case .update: _ = try await interactor.updatePatient(patient: patient, patientId: patient.id)
        }
    }
}

private final class PatientContractNetwork: MockNetworkService {
    struct Request { let path: String; let body: Data? }
    @MainActor private(set) var requests: [Request] = []
    var response: @MainActor (Request) async throws -> Data = { request in try PatientContractNetwork.response(for: request.path) }
    override func get<T: Decodable>(urlString: String, headers: [String: String]?) async throws -> APIResponse<T> {
        try await execute(url: urlString, body: nil)
    }
    override func post<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B) async throws -> APIResponse<T> {
        try await execute(url: urlString, body: JSONEncoder().encode(body))
    }
    override func update<T: Decodable, B: Encodable>(urlString: String, headers: [String: String]?, body: B) async throws -> APIResponse<T> {
        try await execute(url: urlString, body: JSONEncoder().encode(body))
    }
    private func execute<T: Decodable>(url: String, body: Data?) async throws -> APIResponse<T> {
        let request = Request(path: URL(string: url)!.path, body: body)
        await MainActor.run { requests.append(request) }
        let payload = try await response(request)
        return try JSONDecoder().decode(APIResponse<T>.self, from: payload)
    }
    static func patientObject(id: String = "patient-a", birthDate: String = "1990-02-18") -> [String: Any] {
        ["id": id, "name": "Sari", "NIK": "", "DoB": birthDate, "sex": "FEMALE", "medicalRecordNumber": "000042"]
    }
    static func patientData(birthDate: String = "1990-02-18") throws -> Data {
        try JSONSerialization.data(withJSONObject: patientObject(birthDate: birthDate))
    }
    static func envelope(_ data: Any) throws -> Data {
        try JSONSerialization.data(withJSONObject: ["status": "success", "code": 200, "message": "OK", "data": data])
    }
    static func response(for path: String) throws -> Data {
        if path.contains("get-all-patients") { return try envelope([patientObject()]) }
        if path.contains("get-examination-card") { return try envelope([]) }
        return try envelope(patientObject())
    }
}

private actor PatientContractGate {
    private var continuations: [CheckedContinuation<Void, Never>] = []
    private var isOpen = false
    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { continuations.append($0) }
    }
    func open() {
        isOpen = true
        continuations.forEach { $0.resume() }
        continuations.removeAll()
    }
}
