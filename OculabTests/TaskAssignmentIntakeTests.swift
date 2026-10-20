import SwiftUI
import XCTest
@testable import Oculab

final class TaskAssignmentIntakeTests: XCTestCase {
    @MainActor
    private func newFlow(stub: TaskIntakeStub = TaskIntakeStub()) -> TaskAssignmentFlowCoordinator {
        let flow = TaskAssignmentFlowCoordinator(repository: TaskAssignmentRepository(interactor: stub))
        flow.prepareNewPatientSelection(name: "Siti Aminah")
        flow.selectedPIC = "selected-pic"
        return flow
    }

    @MainActor
    private func fill(_ flow: TaskAssignmentFlowCoordinator) {
        flow.selectedDoB = Date(timeIntervalSince1970: 0)
        flow.handleDateOfBirthChange()
        flow.selectedSex = AppPatient.Gender.female
        flow.handleGenderChange()
    }

    @MainActor
    func testWizardNewPatientStartsWithUnknownBirthDateAndSex() {
        let flow = newFlow()
        XCTAssertNil(flow.selectedDoB)
        XCTAssertNil(flow.patient.DoB)
        XCTAssertEqual(flow.patient.sex, .UNKNOWN)
        XCTAssertFalse(flow.isPatientStepReady)
        flow.handleGenderChange()
        XCTAssertEqual(flow.patient.sex, .UNKNOWN, "An unselected sex must not default to male")
    }

    @MainActor
    func testWizardUsesSameOptionalIdentifierRulesWithoutPublishingReadinessErrors() {
        let flow = newFlow()
        fill(flow)
        let priorErrors = flow.validationManager.errors
        for _ in 0..<10 { XCTAssertTrue(flow.isPatientStepReady) }
        XCTAssertEqual(flow.validationManager.errors, priorErrors)
        XCTAssertTrue(flow.validatePatientStepBeforeProceed())
        XCTAssertNil(flow.validationManager.getError(for: ValidationFieldName.patientNIK.fieldName))
        flow.BPJSnumber = "12345678901"
        flow.handleBPJSNumberChange()
        XCTAssertFalse(flow.isPatientStepReady)
        XCTAssertFalse(flow.validatePatientStepBeforeProceed())
        XCTAssertNotNil(flow.validationManager.getError(for: ValidationFieldName.patientBPJS.fieldName))
        flow.BPJSnumber = "1234567890123"
        flow.handleBPJSNumberChange()
        XCTAssertTrue(flow.isPatientStepReady)
        flow.BPJSnumber = " "
        flow.handleBPJSNumberChange()
        XCTAssertTrue(flow.isPatientStepReady)
        XCTAssertNil(flow.patient.BPJS)
    }

    @MainActor
    func testWizardCreatesPatientWithoutNIKAndPreservesLocalRecordNumberCase() async {
        let stub = TaskIntakeStub()
        let flow = newFlow(stub: stub)
        fill(flow)
        flow.patient.NIK = "  "
        flow.patient.medicalRecordNumber = "  RM-001/a  "
        let priorPath = Router.shared.path
        let priorRoute = Router.shared.currentRoute
        defer { Router.shared.path = priorPath; Router.shared.currentRoute = priorRoute }
        await flow.proceedToSpecimenStep()
        XCTAssertEqual(stub.created.count, 1)
        XCTAssertEqual(stub.created.first?.NIK, "")
        XCTAssertEqual(stub.created.first?.medicalRecordNumber, "RM-001/a")
        XCTAssertEqual(flow.savedPatientId, stub.created.first?.id)
        XCTAssertFalse(flow.isError)
    }

    @MainActor
    func testMissingStoredDemographicsStayMissingAndNeverCreateReplacement() async {
        let stub = TaskIntakeStub()
        let id = UUID().uuidString.lowercased()
        stub.lookup = { Patient(id: $0, name: "Existing patient", NIK: "", DoB: nil, sex: .UNKNOWN) }
        let flow = TaskAssignmentFlowCoordinator(repository: TaskAssignmentRepository(interactor: stub), prefillPatientId: id)
        flow.selectedPIC = "selected-pic"
        await flow.handlePatientChoiceChange()
        XCTAssertNil(flow.selectedDoB)
        XCTAssertNil(flow.patient.DoB)
        XCTAssertFalse(flow.isPatientStepReady)
        XCTAssertNotNil(flow.validationManager.getError(for: ValidationFieldName.patientDateOfBirth.fieldName))
        XCTAssertNil(flow.validationManager.getError(for: ValidationFieldName.patientNIK.fieldName))
        await flow.proceedToSpecimenStep()
        XCTAssertTrue(stub.created.isEmpty)
        XCTAssertEqual(flow.patientSelection, .existing(patientId: id))
    }

    @MainActor
    func testPatientLookupLabelIncludesMedicalRecordNumberForSearch() async {
        let stub = TaskIntakeStub()
        stub.patients = { [Patient(id: "patient-a", name: "Siti", NIK: "", DoB: nil, sex: .FEMALE, medicalRecordNumber: "RM-17/a")] }
        let flow = TaskAssignmentFlowCoordinator(repository: TaskAssignmentRepository(interactor: stub))
        await flow.getAllPatient()
        XCTAssertEqual(flow.patientNameDoB.count, 1)
        XCTAssertTrue(flow.patientNameDoB.first?.0.contains("RM-17/a") == true)
        XCTAssertEqual(flow.patientNameDoB.first?.1, "patient-a")
    }

    @MainActor
    func testFailedPatientDirectoryLoadDoesNotClaimThereAreNoPatientsAndCanRetry() async {
        let stub = TaskIntakeStub()
        stub.patients = { throw URLError(.notConnectedToInternet) }
        let flow = TaskAssignmentFlowCoordinator(repository: TaskAssignmentRepository(interactor: stub))
        await flow.getAllPatient()
        flow.markInitialLoadComplete()
        XCTAssertFalse(flow.hasLoadedPatientDirectory)
        XCTAssertFalse(flow.isPatientListEmpty)
        XCTAssertNotNil(flow.patientDirectoryErrorMessage)
        stub.patients = { [] }
        await flow.getAllPatient()
        XCTAssertTrue(flow.hasLoadedPatientDirectory)
        XCTAssertTrue(flow.isPatientListEmpty)
        XCTAssertNil(flow.patientDirectoryErrorMessage)
    }

    @MainActor
    func testLateWizardListResponseCannotRestoreDataAfterSessionGenerationChanges() async {
        let stub = TaskIntakeStub()
        let started = expectation(description: "Wizard patient list held")
        let gate = TaskIntakeGate()
        stub.patients = {
            started.fulfill()
            await gate.wait()
            return [Patient(id: "old", name: "Old patient", NIK: "", DoB: nil, sex: .FEMALE)]
        }
        let flow = TaskAssignmentFlowCoordinator(repository: TaskAssignmentRepository(interactor: stub))
        let request = Task { await flow.getAllPatient() }
        await fulfillment(of: [started], timeout: 2)
        AuthSessionManager.beginSessionChange()
        AuthSessionManager.completeSessionChange()
        await gate.open()
        await request.value
        XCTAssertTrue(flow.patientNameDoB.isEmpty)
        XCTAssertTrue(flow.patient.name.isEmpty)
        XCTAssertNil(flow.patientSelection)
        XCTAssertFalse(flow.isPatientLoading)
    }
}

private final class TaskIntakeStub: InputPatientInteractor {
    var created: [Patient] = []
    var patients: () async throws -> [Patient] = { [] }
    var lookup: (String) async throws -> Patient = { Patient(id: $0, name: "Existing", NIK: "", DoB: nil, sex: .UNKNOWN) }
    override func getAllPatient() async throws -> [Patient] { try await patients() }
    override func getPatientById(patientId: String) async throws -> Patient { try await lookup(patientId) }
    override func addNewPatient(patient: Patient) async throws -> Patient {
        patient.id = UUID().uuidString.lowercased()
        created.append(patient)
        return patient
    }
}

private actor TaskIntakeGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var isOpen = false
    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { continuation = $0 }
    }
    func open() { isOpen = true; continuation?.resume(); continuation = nil }
}
