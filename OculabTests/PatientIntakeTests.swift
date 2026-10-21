import SwiftUI
import UIKit
import XCTest
@testable import Oculab

final class PatientIntakeTests: XCTestCase {
    @MainActor
    private func withFixture(_ body: (PatientIntakeStub, PatientPresenter, Router) async throws -> Void) async rethrows {
        let keys: [KeychainKey] = [.accessToken, .refreshToken, .accessPin]
        let secrets = keys.map { ($0, KeychainHelper.string(for: $0)) }
        let defaults = UserDefaultType.allCases.map { ($0, UserDefaults.standard.object(forKey: $0.rawValue)) }
        defer {
            AuthSessionManager.beginSessionChange()
            for (key, value) in secrets {
                if let value { KeychainHelper.set(value, for: key) } else { KeychainHelper.remove(key) }
            }
            for (key, value) in defaults { UserDefaults.standard.set(value, forKey: key.rawValue) }
            AuthSessionManager.completeSessionChange()
        }
        setSession("patient-owner-a")
        let interactor = PatientIntakeStub()
        let router = Router()
        let presenter = PatientPresenter(interactor: interactor, router: router)
        try await body(interactor, presenter, router)
        presenter.resetState()
    }

    @MainActor
    private func setSession(_ owner: String) {
        AuthSessionManager.beginSessionChange()
        UserDefaults.standard.set(owner, forKey: UserDefaultType.userId.rawValue)
        UserDefaults.standard.set(true, forKey: UserDefaultType.isUserLoggedIn.rawValue)
        KeychainHelper.set(owner + "-access", for: .accessToken)
        AuthSessionManager.completeSessionChange()
    }

    @MainActor
    private func fill(_ presenter: PatientPresenter) {
        presenter.patient.name = "  Siti Aminah  "
        presenter.selectedDoB = Date(timeIntervalSince1970: 0)
        presenter.selectedSex = AppPatient.Gender.female
    }

    @MainActor
    func testNewFormRequiresExplicitBirthDateAndSexWithoutInventingToday() async {
        await withFixture { stub, presenter, _ in
            XCTAssertNil(presenter.patient.DoB)
            XCTAssertNil(presenter.selectedDoB)
            presenter.patient.name = "Siti"
            XCTAssertFalse(presenter.isFormValid)
            await presenter.handleFormSubmission()
            XCTAssertEqual(stub.created.count, 0)
            XCTAssertNotNil(presenter.fieldErrors[.dateOfBirth])
            XCTAssertNotNil(presenter.fieldErrors[.sex])
        }
    }

    @MainActor
    func testReadingReadinessDoesNotPublishValidationErrors() async {
        await withFixture { _, presenter, _ in
            let initialGlobalErrors = ValidationManager.shared.errors
            for _ in 0..<10 { XCTAssertFalse(presenter.isFormValid) }
            XCTAssertTrue(presenter.fieldErrors.isEmpty)
            XCTAssertFalse(presenter.hasAttemptedSubmission)
            XCTAssertEqual(ValidationManager.shared.errors, initialGlobalErrors)
        }
    }

    @MainActor
    func testOptionalIdentifiersSubmitTrimmedWithoutRequiringNationalIdentity() async {
        await withFixture { stub, presenter, _ in
            fill(presenter)
            presenter.patient.NIK = "  "
            presenter.patient.medicalRecordNumber = "  RM-00017/A  "
            presenter.BPJSnumber = "  "
            XCTAssertTrue(presenter.isFormValid)
            await presenter.handleFormSubmission()
            XCTAssertEqual(stub.created.count, 1)
            XCTAssertEqual(stub.created.first?.name, "Siti Aminah")
            XCTAssertEqual(stub.created.first?.NIK, "")
            XCTAssertEqual(stub.created.first?.medicalRecordNumber, "RM-00017/A")
            XCTAssertNil(stub.created.first?.BPJS)
            XCTAssertEqual(stub.created.first?.sex, .FEMALE)
        }
    }

    @MainActor
    func testMalformedProvidedIdentifiersRemainVisibleAndAreNotSilentlyStripped() async {
        await withFixture { stub, presenter, _ in
            fill(presenter)
            presenter.patient.NIK = "123A"
            presenter.BPJSnumber = "123abc"
            await presenter.handleFormSubmission()
            XCTAssertTrue(stub.created.isEmpty)
            XCTAssertNotNil(presenter.fieldErrors[.nik])
            XCTAssertNotNil(presenter.fieldErrors[.bpjs])
            XCTAssertEqual(presenter.patient.NIK, "123A")
            XCTAssertEqual(presenter.BPJSnumber, "123abc")
        }
    }

    @MainActor
    func testFailedEditLoadKeepsEditIdentityAndCannotCreateReplacementPatient() async {
        await withFixture { stub, presenter, _ in
            stub.fetch = { _ in throw URLError(.notConnectedToInternet) }
            await presenter.getPatientById(patientId: "patient-intended")
            fill(presenter)
            XCTAssertEqual(presenter.editingPatientID, "patient-intended")
            XCTAssertFalse(presenter.canSubmit)
            XCTAssertNotNil(presenter.patientLoadErrorMessage)
            await presenter.handleFormSubmission()
            await presenter.addNewPatient()
            XCTAssertTrue(stub.created.isEmpty)
            XCTAssertTrue(stub.updated.isEmpty)
            XCTAssertEqual(presenter.buttonTitle, AppTextPatientCompCard.buttonSavePatient)
        }
    }

    @MainActor
    func testRetryEditLoadsCanonicalPatientAndPreservesMissingDate() async {
        await withFixture { stub, presenter, _ in
            stub.fetch = { _ in throw URLError(.timedOut) }
            await presenter.getPatientById(patientId: "patient-a")
            stub.fetch = { id in Patient(id: id, name: "Existing", NIK: "", DoB: nil, sex: .UNKNOWN) }
            await presenter.retryPatientLoad()
            XCTAssertNil(presenter.patientLoadErrorMessage)
            XCTAssertTrue(presenter.hasLoadedEditingPatient)
            XCTAssertNil(presenter.selectedDoB)
            XCTAssertFalse(presenter.isFormValid)
            fill(presenter)
            await presenter.handleFormSubmission()
            XCTAssertEqual(stub.updated.map(\.0), ["patient-a"])
            XCTAssertTrue(stub.created.isEmpty)
        }
    }

    @MainActor
    func testDuplicateSaveSendsOneSnapshotAndKeepsFormVisible() async {
        await withFixture { stub, presenter, _ in
            fill(presenter)
            let started = expectation(description: "Patient POST held")
            let gate = PatientIntakeGate()
            stub.save = { patient in
                started.fulfill()
                await gate.wait()
                patient.id = "created-patient"
                return patient
            }
            let request = Task { await presenter.handleFormSubmission() }
            await fulfillment(of: [started], timeout: 2)
            XCTAssertTrue(presenter.isSavingPatient)
            XCTAssertFalse(presenter.isPatientLoading)
            await presenter.handleFormSubmission()
            presenter.patient.name = "Changed while request pending"
            XCTAssertEqual(stub.created.count, 1)
            XCTAssertEqual(stub.created.first?.name, "Siti Aminah")
            await gate.open()
            await request.value
            XCTAssertFalse(presenter.isSavingPatient)
        }
    }

    @MainActor
    func testListFailureIsNotAnEmptySuccessAndRetrySearchesMedicalRecordNumber() async {
        await withFixture { stub, presenter, _ in
            stub.list = { throw URLError(.notConnectedToInternet) }
            await presenter.getAllPatient()
            XCTAssertNotNil(presenter.listErrorMessage)
            XCTAssertFalse(presenter.isPatientListEmpty)
            XCTAssertFalse(presenter.hasLoadedPatients)
            stub.list = { [Patient(id: "one", name: "Siti", NIK: "", DoB: nil, sex: .FEMALE, medicalRecordNumber: "RM-001")] }
            await presenter.getAllPatient()
            XCTAssertNil(presenter.listErrorMessage)
            presenter.searchText = " rm-001 "
            presenter.searchPatients()
            XCTAssertEqual(presenter.filteredPatients.map(\.id), ["one"])
            stub.list = { throw URLError(.timedOut) }
            await presenter.getAllPatient()
            XCTAssertEqual(presenter.patients.map(\.id), ["one"])
            XCTAssertNotNil(presenter.listErrorMessage)
        }
    }

    @MainActor
    func testOldPatientLookupCannotReplaceNewerSelection() async {
        await withFixture { stub, presenter, _ in
            let started = expectation(description: "Old patient GET held")
            let gate = PatientIntakeGate()
            stub.fetch = { id in
                if id == "old" { started.fulfill(); await gate.wait() }
                return Patient(id: id, name: id, NIK: "", DoB: nil, sex: .FEMALE)
            }
            let old = Task { await presenter.getPatientById(patientId: "old") }
            await fulfillment(of: [started], timeout: 2)
            await presenter.getPatientById(patientId: "current")
            await gate.open()
            await old.value
            XCTAssertEqual(presenter.patient.id, "current")
            XCTAssertEqual(presenter.editingPatientID, "current")
        }
    }

    @MainActor
    func testCurrentSessionSavePopsOnlyItsOwnInjectedNavigation() async {
        await withFixture { stub, presenter, router in
            fill(presenter)
            router.path.append(Router.Route.patientList)
            router.path.append(Router.Route.patientForm(patientId: nil))
            await presenter.handleFormSubmission()
            XCTAssertEqual(stub.created.count, 1)
            XCTAssertEqual(presenter.patient.id, "created")
            XCTAssertEqual(router.path.count, 1, "A successful save must dismiss only its own form")
            XCTAssertNil(presenter.errorMessage)
            XCTAssertFalse(presenter.isSavingPatient)
        }
    }

    @MainActor
    func testOldSessionListAndSaveCannotPublishPatientOrPopNewNavigation() async {
        for save in [false, true] {
            await withFixture { stub, presenter, router in
                fill(presenter)
                let started = expectation(description: "Patient operation held")
                let gate = PatientIntakeGate()
                stub.list = { started.fulfill(); await gate.wait(); return [Patient(id: "old", name: "Old sensitive data", NIK: "", DoB: nil, sex: .FEMALE)] }
                stub.save = { patient in started.fulfill(); await gate.wait(); patient.id = "old"; return patient }
                let request = Task {
                    if save { await presenter.handleFormSubmission() }
                    else { await presenter.getAllPatient() }
                }
                await fulfillment(of: [started], timeout: 2)
                setSession("patient-owner-b")
                // An isolated router keeps the live test-host NavigationStack
                // from changing this assertion's navigation state.
                router.path.append(Router.Route.privacyPolicy)
                let count = router.path.count
                await gate.open()
                await request.value
                XCTAssertTrue(presenter.patients.isEmpty)
                XCTAssertTrue(presenter.patient.name.isEmpty)
                XCTAssertEqual(router.path.count, count)
                XCTAssertNil(presenter.errorMessage)
                XCTAssertFalse(presenter.isSavingPatient)
            }
        }
    }

    @MainActor
    func testEditingNameAndRecordNumberPreservesUnchangedLegacyBirthDateWireValue() async throws {
        try await withFixture { stub, presenter, _ in
            let legacyDate = "1990-02-18T17:23:45.123Z"
            let payload = Data("{\"id\":\"patient-legacy\",\"name\":\"Siti\",\"NIK\":\"\",\"DoB\":\"\(legacyDate)\",\"sex\":\"FEMALE\"}".utf8)
            let loaded = try JSONDecoder().decode(Patient.self, from: payload)
            stub.fetch = { _ in loaded }
            await presenter.getPatientById(patientId: loaded.id)
            presenter.patient.name = "Updated name"
            presenter.patient.medicalRecordNumber = "RM-001"
            await presenter.handleFormSubmission()
            let snapshot = try XCTUnwrap(stub.updated.first?.1)
            let body = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(snapshot)) as? [String: Any])
            XCTAssertEqual(body["DoB"] as? String, legacyDate,
                           "Changing identity fields must not normalize a historical birth-date timestamp")
            XCTAssertEqual(body["name"] as? String, "Updated name")
            XCTAssertEqual(body["medicalRecordNumber"] as? String, "RM-001")
        }
    }

    @MainActor
    func testPatientIntakeRendersUnselectedDateAndLoadedIdentityAtPhoneWidths() async throws {
        try await withFixture { stub, presenter, _ in
            try await renderIntake(PatientFormField(presenter: presenter).padding(20), width: 375, typeSize: .large, name: "new-patient-empty-date")
            try await renderIntake(PatientFormField(presenter: presenter).padding(20), width: 320, typeSize: .accessibility3, name: "new-patient-accessibility")
            stub.fetch = { id in
                Patient(id: id, name: "Siti Aminah binti Abdullah", NIK: "", DoB: Date(timeIntervalSince1970: 0), sex: .FEMALE, medicalRecordNumber: "RM-000017/A")
            }
            await presenter.getPatientById(patientId: "patient-a")
            try await renderIntake(PatientFormField(presenter: presenter).padding(20), width: 375, typeSize: .large, name: "edit-patient-local-record")
            let failure = PatientLoadErrorView(title: AppTextPatientIntake.patientLoadFailed,
                                              message: "Unable to load this patient. Your changes have not been submitted.", retry: {})
            try await renderIntake(failure.padding(20), width: 320, typeSize: .accessibility3, name: "edit-patient-load-failed")
        }
    }

    @MainActor
    private func renderIntake<Content: View>(_ content: Content, width: CGFloat, typeSize: DynamicTypeSize, name: String) async throws {
        let host = UIHostingController(rootView: content
            .environment(\.dynamicTypeSize, typeSize).environment(\.colorScheme, .light)
            .background(Color.white))
        host.safeAreaRegions = []
        let fitting = host.sizeThatFits(in: CGSize(width: width, height: 10_000))
        XCTAssertTrue(fitting.height.isFinite && fitting.width.isFinite)
        XCTAssertLessThanOrEqual(fitting.width, width + 0.5, "Patient intake must fit the available phone width")
        XCTAssertGreaterThan(fitting.height, 100)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: width, height: fitting.height)
        window.rootViewController = host
        window.isHidden = false
        defer { window.isHidden = true }
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        await Task.yield()
        host.view.layoutIfNeeded()
        let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
            host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = "patient-intake-" + name
        attachment.lifetime = .keepAlways
        add(attachment)
        if let png = image.pngData() {
            try png.write(to: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("oculab-patient-intake-\(name).png"))
        }
    }

    @MainActor
    func testExaminationFailureHasIndependentRecoveryState() async {
        await withFixture { stub, presenter, _ in
            stub.examinations = { _ in throw URLError(.timedOut) }
            await presenter.getPatientById(patientId: "patient-a")
            await presenter.getExaminationsByPatientId(patientId: "patient-a")
            XCTAssertTrue(presenter.hasLoadedEditingPatient)
            XCTAssertNotNil(presenter.examinationsErrorMessage)
            XCTAssertFalse(presenter.hasLoadedExaminations)
            XCTAssertNil(presenter.patientLoadErrorMessage)
            stub.examinations = { _ in [] }
            await presenter.getExaminationsByPatientId(patientId: "patient-a")
            XCTAssertTrue(presenter.hasLoadedExaminations)
            XCTAssertNil(presenter.examinationsErrorMessage)
        }
    }
}

@MainActor
private final class PatientIntakeStub: PatientInteractor {
    var list: () async throws -> [Patient] = { [] }
    var fetch: (String) async throws -> Patient = { Patient(id: $0, name: "Existing", NIK: "", DoB: nil, sex: .FEMALE) }
    var save: (Patient) async throws -> Patient = { patient in patient.id = "created"; return patient }
    var examinations: (String) async throws -> [ExaminationResultCardData] = { _ in [] }
    var created: [Patient] = []
    var updated: [(String, Patient)] = []
    override func getAllPatient() async throws -> [Patient] { try await list() }
    override func getPatientById(patientId: String) async throws -> Patient { try await fetch(patientId) }
    override func addNewPatient(patient: Patient) async throws -> Patient { created.append(patient); return try await save(patient) }
    override func updatePatient(patient: Patient, patientId: String) async throws -> Patient {
        updated.append((patientId, patient)); patient.id = patientId; return patient
    }
    override func getAllExamByPatientId(patientId: String) async throws -> [ExaminationResultCardData] { try await examinations(patientId) }
}

private actor PatientIntakeGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var isOpen = false
    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { continuation = $0 }
    }
    func open() { isOpen = true; continuation?.resume(); continuation = nil }
}
