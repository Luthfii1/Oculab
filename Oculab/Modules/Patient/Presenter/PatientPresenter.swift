import Foundation
import SwiftUI
import Observation

/// Owns the visible patient record, its independent loading states, and an explicit edit identity.
@MainActor
@Observable
class PatientPresenter {
    private let interactor: PatientInteractor
    private let router: Router
    var formValidation = FormValidationViewModel()
    @ObservationIgnored nonisolated(unsafe) private var sessionObserver: NSObjectProtocol?
    private var listRequestID: UUID?
    private var patientRequestID: UUID?
    private var examinationsRequestID: UUID?
    private var saveRequestID: UUID?
    private var formID = UUID()
    private var fetchTask: Task<Void, Never>?
    private(set) var editingPatientID: String?
    private(set) var hasLoadedEditingPatient = false
    private(set) var hasLoadedPatients = false
    private(set) var hasLoadedExaminations = false
    var isPatientLoading = false
    var isSavingPatient = false
    var isLoadingExaminations = false
    var patients: [PatientListItem] = []
    var filteredPatients: [PatientListItem] = []
    var searchText = ""
    var patient = Patient(name: "", NIK: "", DoB: nil, sex: .UNKNOWN)
    var selectedSex = ""
    var BPJSnumber = ""
    var selectedDoB: Date?
    var nameError = ""
    var nikError = ""
    var bpjsError = ""
    var fieldErrors: [PatientIntakeField: String] = [:]
    var hasAttemptedSubmission = false
    var examinationList: [ExaminationResultCardData] = []
    var errorMessage: String?
    var listErrorMessage: String?
    var patientLoadErrorMessage: String?
    var examinationsErrorMessage: String?

    init(interactor: PatientInteractor? = nil, router: Router = .shared) {
        self.interactor = interactor ?? PatientInteractor()
        self.router = router
        sessionObserver = NotificationCenter.default.addObserver(
            forName: AuthSessionManager.sessionDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.clearSessionData() }
        }
    }

    deinit {
        if let sessionObserver { NotificationCenter.default.removeObserver(sessionObserver) }
    }

    var isPatientListEmpty: Bool { hasLoadedPatients && !isPatientLoading && patients.isEmpty && listErrorMessage == nil }
    var canSubmit: Bool { !isPatientLoading && !isSavingPatient && (editingPatientID == nil || hasLoadedEditingPatient) }
    /// Pure checks only: SwiftUI may evaluate this repeatedly while rendering.
    var isFormValid: Bool { canSubmit && PatientIntakeValidation.isReady(patient: formPatient()) }
    var buttonTitle: String { editingPatientID == nil ? AppTextPatientCompCard.buttonCreatePatient : AppTextPatientCompCard.buttonSavePatient }
    var buttonIcon: String { editingPatientID == nil ? AppIcon.add : AppIcon.checkmark }
    var navigationTitle: String { editingPatientID == nil ? AppTextPatientForm.newPatientNavigationTitle : AppTextPatientForm.editPatientNavigationTitle }

    func setupForm(patientId: String?) {
        let requestedID = patientId?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let requestedID, !requestedID.isEmpty {
            // Set the mode before making a request. A failed GET must never become a POST.
            editingPatientID = requestedID
            hasLoadedEditingPatient = false
            formID = UUID()
            fetchTask?.cancel()
            fetchTask = Task { [weak self] in await self?.getPatientById(patientId: requestedID) }
        }
    }

    func retryPatientLoad() async {
        guard let editingPatientID else { return }
        await getPatientById(patientId: editingPatientID)
    }

    func resetState() {
        fetchTask?.cancel()
        fetchTask = nil
        formID = UUID()
        listRequestID = nil
        patientRequestID = nil
        examinationsRequestID = nil
        saveRequestID = nil
        isPatientLoading = false
        isLoadingExaminations = false
        isSavingPatient = false
    }

    private func clearSessionData() {
        resetState()
        patient = Patient(name: "", NIK: "", DoB: nil, sex: .UNKNOWN)
        selectedSex = ""
        selectedDoB = nil
        BPJSnumber = ""
        patients = []
        filteredPatients = []
        examinationList = []
        searchText = ""
        editingPatientID = nil
        hasLoadedEditingPatient = false
        hasLoadedPatients = false
        hasLoadedExaminations = false
        errorMessage = nil
        listErrorMessage = nil
        patientLoadErrorMessage = nil
        examinationsErrorMessage = nil
        fieldErrors = [:]
        hasAttemptedSubmission = false
        nameError = ""
        nikError = ""
        bpjsError = ""
    }

    func handleNameChange() { refreshFieldError(.name) }
    func handleNIKChange() { refreshFieldError(.nik) }
    func handleMedicalRecordChange() { refreshFieldError(.medicalRecordNumber) }
    func handleDateOfBirthChange() { patient.DoB = selectedDoB; refreshFieldError(.dateOfBirth) }
    func handleGenderChange() {
        patient.sex = selectedSex == AppPatient.Gender.female ? .FEMALE : selectedSex == AppPatient.Gender.male ? .MALE : .UNKNOWN
        refreshFieldError(.sex)
    }
    func handleBPJSChange() { patient.BPJS = BPJSnumber.isEmpty ? nil : BPJSnumber; refreshFieldError(.bpjs) }
    private func refreshFieldError(_ field: PatientIntakeField) {
        guard hasAttemptedSubmission || fieldErrors[field] != nil else { return }
        fieldErrors[field] = PatientIntakeValidation.errors(for: formPatient())[field]
    }
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    private func formPatient() -> Patient {
        let recordNumber = patient.medicalRecordNumber?.trimmingCharacters(in: .whitespacesAndNewlines)
        let snapshot = Patient(id: patient.id, name: patient.name.trimmingCharacters(in: .whitespacesAndNewlines),
                       NIK: patient.NIK.trimmingCharacters(in: .whitespacesAndNewlines), DoB: selectedDoB,
                       sex: selectedSex == AppPatient.Gender.female ? .FEMALE : selectedSex == AppPatient.Gender.male ? .MALE : .UNKNOWN,
                       BPJS: BPJSnumber.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                       medicalRecordNumber: recordNumber?.nilIfEmpty)
        snapshot.preserveBirthDateEncoding(from: patient)
        return snapshot
    }
    @discardableResult
    func validatePatientForm() -> Bool {
        hasAttemptedSubmission = true
        fieldErrors = PatientIntakeValidation.errors(for: formPatient())
        return fieldErrors.isEmpty
    }
    func handleFormSubmission() async {
        guard canSubmit, validatePatientForm() else { return }
        await savePatient()
    }
    func addNewPatientWithValidation() async { await handleFormSubmission() }
    func updatePatientWithValidation() async { await handleFormSubmission() }
    func addNewPatient() async { guard editingPatientID == nil else { return }; await handleFormSubmission() }
    func updatePatient() async { guard editingPatientID != nil else { return }; await handleFormSubmission() }

    private func savePatient() async {
        guard let session = AuthSessionManager.uploadQueueSession, canSubmit else { return }
        let requestID = UUID()
        let requestedForm = formID
        let intendedID = editingPatientID
        let submitted = formPatient()
        saveRequestID = requestID
        isSavingPatient = true
        errorMessage = nil
        defer { if saveRequestID == requestID { isSavingPatient = false; saveRequestID = nil } }
        do {
            let saved: Patient
            if let intendedID {
                saved = try await interactor.updatePatient(patient: submitted, patientId: intendedID)
            } else {
                saved = try await interactor.addNewPatient(patient: submitted)
            }
            guard isCurrent(session), formID == requestedForm, saveRequestID == requestID else { return }
            if let intendedID, saved.id.lowercased() != intendedID.lowercased() { throw URLError(.badServerResponse) }
            patient = saved
            // Keep navigation within the same checked session; Router.navigateBack dispatches asynchronously.
            if !router.path.isEmpty { router.path.removeLast() }
        } catch {
            guard isCurrent(session), formID == requestedForm, saveRequestID == requestID, !isCancellation(error) else { return }
            errorMessage = ErrorHandler.shared.handleError(error, context: .patientManagement)
        }
    }

    func getAllPatient() async {
        guard let session = AuthSessionManager.uploadQueueSession else { return }
        let requestID = UUID()
        listRequestID = requestID
        isPatientLoading = true
        listErrorMessage = nil
        defer { if listRequestID == requestID { isPatientLoading = false } }
        do {
            let response = try await interactor.getAllPatient()
            guard isCurrent(session), listRequestID == requestID else { return }
            patients = response.map { PatientListItem(id: $0.id, name: $0.name, nik: $0.NIK, bpjs: $0.BPJS ?? "", birthDate: formatDate($0.DoB), medicalRecordNumber: $0.medicalRecordNumber ?? "") }
            hasLoadedPatients = true
            filterPatients()
        } catch {
            guard isCurrent(session), listRequestID == requestID, !isCancellation(error) else { return }
            if isEmptyPatientListError(error) { patients = []; hasLoadedPatients = true; filterPatients() }
            else { listErrorMessage = ErrorHandler.shared.handleError(error, context: .patientManagement) }
        }
    }

    func getPatientById(patientId: String) async {
        guard let session = AuthSessionManager.uploadQueueSession else { return }
        let requestedID = patientId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !requestedID.isEmpty else { return }
        if editingPatientID?.lowercased() != requestedID.lowercased() { hasLoadedEditingPatient = false }
        editingPatientID = requestedID
        let requestID = UUID()
        patientRequestID = requestID
        isPatientLoading = true
        patientLoadErrorMessage = nil
        defer { if patientRequestID == requestID { isPatientLoading = false } }
        do {
            let fetched = try await interactor.getPatientById(patientId: requestedID)
            guard isCurrent(session), patientRequestID == requestID else { return }
            guard fetched.id.lowercased() == requestedID.lowercased() else { throw URLError(.badServerResponse) }
            patient = fetched
            BPJSnumber = fetched.BPJS ?? ""
            selectedDoB = fetched.DoB
            selectedSex = fetched.sex == .FEMALE ? AppPatient.Gender.female : fetched.sex == .MALE ? AppPatient.Gender.male : ""
            hasLoadedEditingPatient = true
            fieldErrors = [:]
            hasAttemptedSubmission = false
        } catch {
            guard isCurrent(session), patientRequestID == requestID, !isCancellation(error) else { return }
            hasLoadedEditingPatient = false
            patientLoadErrorMessage = ErrorHandler.shared.handleError(error, context: .patientManagement)
        }
    }

    func getExaminationsByPatientId(patientId: String) async {
        guard let session = AuthSessionManager.uploadQueueSession else { return }
        let requestID = UUID()
        examinationsRequestID = requestID
        isLoadingExaminations = true
        examinationsErrorMessage = nil
        defer { if examinationsRequestID == requestID { isLoadingExaminations = false } }
        do {
            let response = try await interactor.getAllExamByPatientId(patientId: patientId)
            guard isCurrent(session), examinationsRequestID == requestID else { return }
            examinationList = response
            hasLoadedExaminations = true
        } catch {
            guard isCurrent(session), examinationsRequestID == requestID, !isCancellation(error) else { return }
            examinationsErrorMessage = ErrorHandler.shared.handleError(error, context: .patientManagement)
        }
    }
    private func isCurrent(_ session: UploadQueueSession) -> Bool { !Task.isCancelled && session == AuthSessionManager.uploadQueueSession }
    private func isCancellation(_ error: Error) -> Bool { error is CancellationError || (error as? URLError)?.code == .cancelled }
    func searchPatients() { filterPatients() }
    func clearSearch() { searchText = ""; filterPatients() }
    private func filterPatients() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        filteredPatients = query.isEmpty ? patients : patients.filter {
            $0.name.localizedCaseInsensitiveContains(query) || $0.nik.localizedCaseInsensitiveContains(query)
                || $0.bpjs.localizedCaseInsensitiveContains(query) || $0.medicalRecordNumber.localizedCaseInsensitiveContains(query)
        }
    }
    func navigateTo(_ destination: Router.Route) { router.navigateTo(destination) }
    func navigateBack() { router.navigateBack() }
    func formatDate(_ date: Date?) -> String { date?.formatted(date: .numeric, time: .omitted) ?? AppTextPatientIntake.missingValue }
    func formatDateTime(_ date: Date) -> String { date.formatted(date: .numeric, time: .shortened) }
    private func isEmptyPatientListError(_ error: Error) -> Bool {
        guard case let NetworkError.apiError(response, _) = error else { return false }
        return response.data.errorType == "RESOURCE_NOT_FOUND" && response.data.description == "No patients found"
    }
}

struct PatientListItem: Identifiable, Equatable {
    let id: String
    let name: String
    let nik: String
    let bpjs: String
    let birthDate: String
    var medicalRecordNumber: String = ""
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
