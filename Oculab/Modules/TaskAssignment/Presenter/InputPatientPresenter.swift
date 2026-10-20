//
//  InputPatientPresenter.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 07/11/24.
//

import Combine
import Foundation
import SwiftUI

/// Shared coordinator for the patient → specimen task-assignment wizard.
final class TaskAssignmentFlowCoordinator: ObservableObject {
    // MARK: - Dependencies
    private let repository: TaskAssignmentRepository
    let validationManager: ValidationManager
    private var validationCancellable: AnyCancellable?
    private var patientLookupID: UUID?
    private var picLookupID: UUID?
    private var patientSaveTask: Task<Void, Never>?
    private var patientSaveID: UUID?
    private var sessionObserver: NSObjectProtocol?

    // MARK: - Published Properties
    @Published var selectedPIC: String = AppValue.empty {
        didSet {
            handlePICChange()
        }
    }
    @Published var patientSelection: PatientSelection?
    
    // MARK: - UI State
    @Published var isAddingNewPatient: Bool = false
    @Published var isError: Bool = false
    @Published var errorMessage: String = AppValue.empty
    @Published var isUserLoading = false
    @Published var isPatientLoading = false
    @Published var hasCompletedInitialLoad = false
    @Published private(set) var hasLoadedPatientDirectory = false
    @Published private(set) var patientDirectoryErrorMessage: String?
    @Published var isSavingPatient = false
    /// Canonical server patient id after `ensurePatientOnServer` (single source of truth).
    @Published private(set) var savedPatientId: String = AppValue.empty
    /// Patient id from navigation — preserved even if a later fetch fails.
    @Published private(set) var examinationPatientId: String = AppValue.empty
    /// PIC id from navigation — preserved even if a later fetch fails.
    @Published private(set) var examinationPICId: String = AppValue.empty
    @Published var isSubmittingExamination = false
    @Published var isSubmitPopUpVisible: Bool = false
    @Published var isSlide2Visible: Bool = false
    /// When false, specimen fields stay neutral until the user taps Create Task.
    @Published var specimenValidationAttempted: Bool = false
    // MARK: - Slide 2 UI Logic
    /// Toggle Slide 2 visibility and clear data if hiding
    func toggleSlide2() {
        if isSlide2Visible {
            isSlide2Visible = false
            examination2 = Examination.empty
            typeString2 = AppValue.empty
            validationManager.clearError(for: ValidationFieldName.slideId2.fieldName)
            validationManager.clearError(for: ValidationFieldName.slideType2.fieldName)
        } else {
            isSlide2Visible = true
        }
    }

    /// Button title for toggling slide 2
    var slide2ButtonTitle: String {
        isSlide2Visible ? AppTextTaskAssignInputExam.removeSlide2Button : AppTextTaskAssignInputExam.addSlide2Button
    }

    /// Button color for toggling slide 2
    var slide2ButtonColor: AppButton.ButtonColorType {
        isSlide2Visible ? .destructive(.secondary) : .secondary
    }
    
    // MARK: - Form State
    @Published var goalString: String = AppValue.empty
    @Published var typeString: String = AppValue.empty
    @Published var typeString2: String = AppValue.empty
    @Published var selectedSex: String = AppValue.empty
    @Published var selectedDoB: Date?
    @Published var BPJSnumber: String = AppValue.empty
    @Published var isAddingName: Bool = false
    
    // MARK: - Data Collections
    @Published var picName: [(String, String)] = []
    @Published var patientNameDoB: [(String, String)] = []
    
    // MARK: - Domain Models
    @Published var patient: Patient = Patient.empty
    @Published var pic: User = User.empty
    @Published var examination: Examination = Examination.empty
    @Published var examination2: Examination = Examination.empty
    
    @Published var patientFound: Bool = false {
        didSet {
            if patientFound {
                updatePatientForm()
            }
        }
    }
    
    // MARK: - Initialization
    init(
        repository: TaskAssignmentRepository = TaskAssignmentRepository(),
        validationManager: ValidationManager = ValidationManager(),
        prefillPatientId: String? = nil
    ) {
        self.repository = repository
        self.validationManager = validationManager
        if let prefill = prefillPatientId?.trimmingCharacters(in: .whitespacesAndNewlines),
           !prefill.isEmpty {
            savedPatientId = prefill
            examinationPatientId = prefill
            patientSelection = .existing(patientId: prefill)
        }

        validationCancellable = validationManager.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        sessionObserver = NotificationCenter.default.addObserver(forName: AuthSessionManager.sessionDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.patientSaveTask?.cancel()
                self.patientSaveTask = nil
                self.patientSaveID = nil
                self.patientLookupID = nil
                self.picLookupID = nil
                self.clearForm()
                self.selectedPIC = ""
                self.pic = User.empty
                self.picName = []
                self.patientNameDoB = []
                self.isUserLoading = false
                self.isSavingPatient = false
                self.isSubmittingExamination = false
                self.examination = Examination.empty
                self.examination2 = Examination.empty
                self.hasCompletedInitialLoad = false
                self.hasLoadedPatientDirectory = false
                self.patientDirectoryErrorMessage = nil
                self.examinationPICId = ""
                self.validationManager.clearAllErrors()
                self.resetErrorState()
            }
        }
    }

    deinit {
        if let sessionObserver { NotificationCenter.default.removeObserver(sessionObserver) }
    }

    var knownPatientIds: Set<String> {
        Set(patientNameDoB.map(\.1))
    }
    
    // MARK: - Computed Properties
    var isInitialLoading: Bool {
        !hasCompletedInitialLoad && (isUserLoading || isPatientLoading)
    }

    var isPatientListEmpty: Bool {
        hasLoadedPatientDirectory && patientDirectoryErrorMessage == nil && patientNameDoB.isEmpty
    }

    var selectedPatientDisplayName: String {
        if !patient.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return patient.name
        }
        if let selection = patientSelection {
            if let match = patientNameDoB.first(where: { $0.1 == selection.valueForBinding }) {
                return match.0
            }
            return selection.newPatientName ?? selection.valueForBinding
        }
        return AppValue.empty
    }

    /// Read-only check for enabling Create Task (no error mutation, safe in SwiftUI `body`).
    var isSpecimenStepReady: Bool {
        let validGoal = validationManager.meetsRequired(goalString)
        let validType1 = validationManager.meetsRequired(typeString)
        let validSlideId1 = validationManager.meetsRequired(examination.slideId)

        if isSlide2Visible {
            let validType2 = validationManager.meetsRequired(typeString2)
            let validSlideId2 = validationManager.meetsRequired(examination2.slideId)
            return validGoal && validType1 && validSlideId1 && validType2 && validSlideId2 && !hasDuplicateSlideIDs
        }
        return validGoal && validType1 && validSlideId1
    }

    var hasDuplicateSlideIDs: Bool {
        let first = examination.slideId.trimmingCharacters(in: .whitespacesAndNewlines)
        let second = examination2.slideId.trimmingCharacters(in: .whitespacesAndNewlines)
        return isSlide2Visible && !first.isEmpty && first == second
    }

    @discardableResult
    func validateSpecimenStepBeforeProceed() -> Bool {
        validationManager.clearAllErrors()

        let validGoal = validationManager.validateRequired(
            goalString,
            fieldName: ValidationFieldName.examinationGoal.fieldName
        )
        let validType1 = validationManager.validateRequired(
            typeString,
            fieldName: ValidationFieldName.slideType1.fieldName
        )
        let validSlideId1 = validationManager.validateRequired(
            examination.slideId,
            fieldName: ValidationFieldName.slideId1.fieldName
        )

        if isSlide2Visible {
            let validType2 = validationManager.validateRequired(
                typeString2,
                fieldName: ValidationFieldName.slideType2.fieldName
            )
            let validSlideId2 = validationManager.validateRequired(
                examination2.slideId,
                fieldName: ValidationFieldName.slideId2.fieldName
            )
            if hasDuplicateSlideIDs {
                validationManager.setError(
                    AppTextTaskAssignInputExam.warningSlideIDsMustBeDifferent,
                    for: ValidationFieldName.slideId2.fieldName
                )
            }
            return validGoal && validType1 && validSlideId1 && validType2 && validSlideId2 && !hasDuplicateSlideIDs
        }
        return validGoal && validType1 && validSlideId1
    }

    func clearSpecimenFieldErrors() {
        [
            ValidationFieldName.examinationGoal,
            .slideId1,
            .slideId2,
            .slideType1,
            .slideType2,
        ].forEach { validationManager.clearError(for: $0.fieldName) }
    }
    
    /// Read-only check for enabling the proceed button (no error mutation, safe in SwiftUI `body`).
    var isPatientStepReady: Bool {
        guard !isPatientLoading, hasResolvedPatientSelection else { return false }
        let validPIC = validationManager.meetsRequired(selectedPIC)
        let validPatientSelection = validationManager.meetsRequired(
            patientSelection?.valueForBinding ?? AppValue.empty
        )
        return validPIC && validPatientSelection && PatientIntakeValidation.isReady(patient: patientIntakeDraft())
    }

    /// Run on submit only; computed readiness never publishes errors.
    @discardableResult
    func validatePatientStepBeforeProceed() -> Bool {
        guard !isPatientLoading, hasResolvedPatientSelection else { return false }
        validationManager.clearAllErrors()
        let validPIC = validationManager.validateRequired(selectedPIC, fieldName: ValidationFieldName.userRole.fieldName)
        let validSelection = validationManager.validateRequired(patientSelection?.valueForBinding ?? "", fieldName: ValidationFieldName.patientName.fieldName)
        let errors = PatientIntakeValidation.errors(for: patientIntakeDraft())
        for (field, message) in errors { validationManager.setError(message, for: field.validationKey) }
        return validPIC && validSelection && errors.isEmpty
    }

    /// A detached snapshot prevents edits while awaiting persistence from changing its request.
    private func patientIntakeDraft() -> Patient {
        let cleanBPJS = BPJSnumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanMRN = patient.medicalRecordNumber?.trimmingCharacters(in: .whitespacesAndNewlines)
        let draft = Patient(id: patient.id, name: patient.name.trimmingCharacters(in: .whitespacesAndNewlines),
                            NIK: patient.NIK.trimmingCharacters(in: .whitespacesAndNewlines), DoB: patient.DoB,
                            sex: selectedSex == AppPatient.Gender.male ? .MALE : selectedSex == AppPatient.Gender.female ? .FEMALE : .UNKNOWN,
                            BPJS: cleanBPJS.isEmpty ? nil : cleanBPJS,
                            medicalRecordNumber: cleanMRN?.isEmpty == false ? cleanMRN : nil)
        draft.preserveBirthDateEncoding(from: patient)
        return draft
    }

    private func updatePatientFieldError(_ field: PatientIntakeField) {
        if let message = PatientIntakeValidation.errors(for: patientIntakeDraft())[field] {
            validationManager.setError(message, for: field.validationKey)
        } else {
            validationManager.clearError(for: field.validationKey)
        }
        objectWillChange.send()
    }
    
    // MARK: - Helper Methods
    private var hasResolvedPatientSelection: Bool {
        switch patientSelection {
        case .existing(let id):
            return patientFound && patient.id.lowercased() == id.lowercased()
                && savedPatientId.lowercased() == id.lowercased()
        case .new(let name):
            return isAddingNewPatient && patient.id.isEmpty && patient.name == name
        case nil:
            return false
        }
    }

    private func updatePatientForm() {
        Logger.info("Patient record loaded", category: .taskAssignment)
        selectedDoB = patient.DoB
        selectedSex = patient.sex == .MALE ? AppPatient.Gender.male : 
                     patient.sex == .FEMALE ? AppPatient.Gender.female : AppValue.empty
        BPJSnumber = patient.BPJS ?? AppValue.empty
        
        // Stored missing demographics remain missing and are repairable through Edit Patient.
        let errors = PatientIntakeValidation.errors(for: patientIntakeDraft())
        for field in PatientIntakeField.allCases {
            if let message = errors[field] { validationManager.setError(message, for: field.validationKey) }
            else { validationManager.clearError(for: field.validationKey) }
        }
    }
    
    private func resetErrorState() {
        isError = false
        errorMessage = AppValue.empty
    }
}

// MARK: - Network Operations
extension TaskAssignmentFlowCoordinator {
    @MainActor
    func getAllUser() async {
        let generation = AuthSessionManager.authenticationSessionGeneration
        isUserLoading = true
        defer { if generation == AuthSessionManager.authenticationSessionGeneration { isUserLoading = false } }
        
        do {
            let users = try await repository.fetchPICs()
            guard !Task.isCancelled, generation == AuthSessionManager.authenticationSessionGeneration else { return }
            picName = users.map { ($0.name, $0.id) }
        } catch {
            guard !Task.isCancelled, generation == AuthSessionManager.authenticationSessionGeneration else { return }
            errorMessage = ErrorHandler.shared.handleError(error, context: .generic)
            isError = true
        }
    }

    @MainActor
    func getAllPatient() async {
        let generation = AuthSessionManager.authenticationSessionGeneration
        isPatientLoading = true
        patientDirectoryErrorMessage = nil
        defer { if generation == AuthSessionManager.authenticationSessionGeneration { isPatientLoading = false } }
        
        do {
            let patients = try await repository.fetchPatients()
            guard !Task.isCancelled, generation == AuthSessionManager.authenticationSessionGeneration else { return }
            hasLoadedPatientDirectory = true
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = AppConstants.PatientUI.dateFormat
            
            patientNameDoB = patients.map { patient in
                let formattedDoB = patient.DoB.map { dateFormatter.string(from: $0) } ?? AppValue.empty
                let recordNumber = patient.medicalRecordNumber?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let label = [patient.name, formattedDoB, recordNumber].filter { !$0.isEmpty }.joined(separator: " · ")
                return (label, patient.id)
            }
        } catch {
            guard !Task.isCancelled, generation == AuthSessionManager.authenticationSessionGeneration else { return }
            if repository.isEmptyPatientListError(error) {
                patientNameDoB = []
                hasLoadedPatientDirectory = true
                return
            }
            patientDirectoryErrorMessage = ErrorHandler.shared.handleError(error, context: .generic)
        }
    }

    @MainActor
    func getPatientById(patientId: String, preserveIdentityOnFailure: Bool = false) async {
        guard let selection = PatientSelection.from(
            bindingValue: patientId,
            knownPatientIds: knownPatientIds
        ) else { return }

        switch selection {
        case .existing(let id):
            patientSelection = .existing(patientId: id)
            await loadExistingPatient(id: id, preserveIdentityOnFailure: preserveIdentityOnFailure)
        case .new(let name):
            patientSelection = .new(displayName: name)
            prepareNewPatientSelection(name: name)
        }
    }

    @MainActor
    func loadExistingPatient(id: String, preserveIdentityOnFailure: Bool) async {
        let generation = AuthSessionManager.authenticationSessionGeneration
        let trimmedId = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedId.isEmpty else { return }

        let lookupID = UUID()
        patientLookupID = lookupID
        let requestedSelection = patientSelection
        isPatientLoading = true
        defer {
            if patientLookupID == lookupID { isPatientLoading = false }
        }

        do {
            let loaded = try await repository.fetchPatient(id: trimmedId)
            guard !Task.isCancelled, generation == AuthSessionManager.authenticationSessionGeneration, patientLookupID == lookupID,
                  patientSelection == requestedSelection else { return }
            patient = loaded
            patientFound = true
            isAddingNewPatient = false
            patientSelection = .existing(patientId: loaded.id)
            savedPatientId = loaded.id
            examinationPatientId = loaded.id
        } catch {
            guard !Task.isCancelled, generation == AuthSessionManager.authenticationSessionGeneration, !(error is CancellationError),
                  (error as? URLError)?.code != .cancelled,
                  patientLookupID == lookupID,
                  patientSelection == requestedSelection else { return }
            if preserveIdentityOnFailure {
                Logger.warning(
                    "Could not load patient \(trimmedId); keeping examination context",
                    category: .taskAssignment
                )
            } else {
                clearForm()
                errorMessage = ErrorHandler.shared.handleError(error, context: .generic)
                isError = true
            }
        }
    }

    @MainActor
    func prepareNewPatientSelection(name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        patientLookupID = nil
        isPatientLoading = false
        patientFound = false
        isAddingNewPatient = true
        patientSelection = .new(displayName: trimmedName)
        savedPatientId = AppValue.empty
        examinationPatientId = AppValue.empty
        patient = Patient.empty
        patient.name = trimmedName
        selectedDoB = nil
        selectedSex = AppValue.empty
        BPJSnumber = AppValue.empty
        validationManager.clearAllErrors()
    }

    @MainActor
    func markInitialLoadComplete() {
        hasCompletedInitialLoad = true
    }

    @MainActor
    func getUserById(userId: String) async {
        let generation = AuthSessionManager.authenticationSessionGeneration
        let lookupID = UUID()
        picLookupID = lookupID
        let requestedPIC = selectedPIC
        isUserLoading = true
        defer {
            if picLookupID == lookupID { isUserLoading = false }
        }
        
        do {
            let user = try await repository.fetchUser(id: userId)
            guard !Task.isCancelled, generation == AuthSessionManager.authenticationSessionGeneration, picLookupID == lookupID,
                  selectedPIC == requestedPIC else { return }
            self.pic = user
        } catch {
            guard !Task.isCancelled, generation == AuthSessionManager.authenticationSessionGeneration, !(error is CancellationError),
                  (error as? URLError)?.code != .cancelled,
                  picLookupID == lookupID,
                  selectedPIC == requestedPIC else { return }
            errorMessage = ErrorHandler.shared.handleError(error, context: .generic)
            isError = true
        }
    }
    
    private func applyPersistedPatient(_ persisted: Patient) {
        patient = persisted
        patientSelection = .existing(patientId: persisted.id)
        savedPatientId = persisted.id
        examinationPatientId = persisted.id
        patientFound = true
        isAddingNewPatient = false
    }
}

// MARK: - Patient Management
extension TaskAssignmentFlowCoordinator {
    func clearForm() {
        patientLookupID = nil
        isPatientLoading = false
        patientFound = false
        isAddingNewPatient = false
        patientSelection = nil
        savedPatientId = AppValue.empty
        examinationPatientId = AppValue.empty
        patient = Patient.empty
        selectedDoB = nil
        selectedSex = AppValue.empty
        BPJSnumber = AppValue.empty
        validationManager.clearAllErrors()
    }
    
    @MainActor
    @discardableResult
    func newExam() -> Task<Void, Never> {
        if let patientSaveTask { return patientSaveTask }
        let saveID = UUID()
        patientSaveID = saveID
        let task = Task { [weak self] in
            guard let self else { return }
            defer {
                if self.patientSaveID == saveID {
                    self.patientSaveTask = nil
                    self.patientSaveID = nil
                }
            }
            await self.proceedToSpecimenStep()
        }
        patientSaveTask = task
        return task
    }

    @MainActor
    func cancelPendingPatientSave() {
        patientSaveTask?.cancel()
    }

    /// Single persistence point before leaving step 1.
    @MainActor
    func proceedToSpecimenStep() async {
        let generation = AuthSessionManager.authenticationSessionGeneration
        guard !isSavingPatient else { return }
        guard validatePatientStepBeforeProceed() else { return }

        let requestedSelection = patientSelection
        let requestedPIC = selectedPIC
        isSavingPatient = true
        defer { if generation == AuthSessionManager.authenticationSessionGeneration { isSavingPatient = false } }

        do {
            syncPatientNameFromSelection()

            let picId = selectedPIC.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !picId.isEmpty else { throw TaskAssignmentFlowError.missingPic }

            let preferredId = savedPatientId.isEmpty ? patient.id : savedPatientId
            let persisted = try await repository.ensurePatientOnServer(
                draft: patientIntakeDraft(),
                preferredId: preferredId
            )
            guard !Task.isCancelled, generation == AuthSessionManager.authenticationSessionGeneration, patientSelection == requestedSelection,
                  selectedPIC == requestedPIC else { return }
            applyPersistedPatient(persisted)

            examinationPICId = picId
            let route = Router.Route.newExam(patientId: persisted.id, picId: picId)
            Router.shared.currentRoute = route
            Router.shared.path.append(route)
        } catch let flowError as TaskAssignmentFlowError {
            guard !Task.isCancelled, generation == AuthSessionManager.authenticationSessionGeneration, patientSelection == requestedSelection,
                  selectedPIC == requestedPIC else { return }
            errorMessage = flowError.localizedDescription
            isError = true
        } catch {
            guard !Task.isCancelled, generation == AuthSessionManager.authenticationSessionGeneration, !(error is CancellationError),
                  (error as? URLError)?.code != .cancelled,
                  patientSelection == requestedSelection, selectedPIC == requestedPIC else { return }
            errorMessage = ErrorHandler.shared.handleError(error, context: .patientManagement)
            isError = true
        }
    }

    /// Step 2 entry — refresh display names; patient is already persisted.
    @MainActor
    func bootstrapSpecimenStep() async {
        specimenValidationAttempted = false
        clearSpecimenFieldErrors()

        let picId = examinationPICId.isEmpty ? selectedPIC : examinationPICId
        if !picId.isEmpty {
            await getUserById(userId: picId)
        }

        let patientId = savedPatientId.isEmpty ? examinationPatientId : savedPatientId
        guard !patientId.isEmpty else { return }
        await getPatientById(patientId: patientId, preserveIdentityOnFailure: true)
        Logger.info("Specimen step bootstrapped for patient \(patientId)", category: .taskAssignment)
    }

    /// Deeplink / legacy route: attach ids when opening specimen step without step 1.
    func attachSpecimenRouteContext(patientId: String, picId: String) {
        let trimmedPatient = patientId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPic = picId.trimmingCharacters(in: .whitespacesAndNewlines)
        if savedPatientId.isEmpty, TaskAssignmentIdentifiers.isPatientId(trimmedPatient) {
            savedPatientId = trimmedPatient
            examinationPatientId = trimmedPatient
            patientSelection = .existing(patientId: trimmedPatient)
        }
        if examinationPICId.isEmpty, !trimmedPic.isEmpty {
            examinationPICId = trimmedPic
            selectedPIC = trimmedPic
        }
    }

    func setupExaminationData(selectedPIC: String, selectedPatient: String) {
        attachSpecimenRouteContext(patientId: selectedPatient, picId: selectedPIC)
        Task {
            await bootstrapSpecimenStep()
        }
    }
}

/// Backward-compatible name used by views and components.
typealias InputPatientPresenter = TaskAssignmentFlowCoordinator

// MARK: - Examination Submission
extension TaskAssignmentFlowCoordinator {
    @MainActor
    func submitExamination() async {
        let generation = AuthSessionManager.authenticationSessionGeneration
        guard !isSubmittingExamination else { return }
        isSubmittingExamination = true
        defer { if generation == AuthSessionManager.authenticationSessionGeneration { isSubmittingExamination = false } }

        guard let DPJPId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            errorMessage = AppTextTaskAssignInputExam.errorMessageFailedToGetResponse
            isError = true
            Logger.error("Submit failed: missing DPJP user id in UserDefaults", category: .taskAssignment)
            return
        }
        
        do {
            let patientId = try await resolvedServerPatientIdForSubmit()
            guard !Task.isCancelled, generation == AuthSessionManager.authenticationSessionGeneration else { return }
            let examinationsToSend = try buildExaminationRequests(DPJPId: DPJPId)
            let response = try await repository.createExaminations(
                patientId: patientId,
                examinations: examinationsToSend
            )
            guard !Task.isCancelled, generation == AuthSessionManager.authenticationSessionGeneration else { return }
            try validateExaminationResponse(response, expectedCount: examinationsToSend.count)
            Router.shared.endTaskAssignmentFlow()
            if !Router.shared.path.isEmpty { Router.shared.path.removeLast(Router.shared.path.count) }
            Router.shared.currentRoute = nil
        } catch let error as ExaminationError {
            guard !Task.isCancelled, generation == AuthSessionManager.authenticationSessionGeneration else { return }
            showError(error.message)
        } catch {
            guard !Task.isCancelled, generation == AuthSessionManager.authenticationSessionGeneration else { return }
            errorMessage = ErrorHandler.shared.handleError(error, context: .examination)
            isError = true
        }
    }
    
    private func buildExaminationRequests(DPJPId: String) throws -> [ExaminationRequest] {
        let hasSecondExam = examination2.preparationType != nil || !examination2.slideId.isEmpty
        
        if hasSecondExam {
            return try buildTwoExaminationRequests(DPJPId: DPJPId)
        } else {
            return try buildSingleExaminationRequest(DPJPId: DPJPId)
        }
    }
    
    private func buildTwoExaminationRequests(DPJPId: String) throws -> [ExaminationRequest] {
        guard examination.preparationType != nil && !examination.slideId.isEmpty else {
            throw ExaminationError.firstExamIncomplete
        }
        
        guard examination2.preparationType != nil && !examination2.slideId.isEmpty else {
            throw ExaminationError.secondExamIncomplete
        }
        
        guard examination.slideId.trimmingCharacters(in: .whitespacesAndNewlines)
            != examination2.slideId.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw ExaminationError.duplicateSlideIds
        }
        
        return [
            createExaminationRequest(from: examination, DPJPId: DPJPId),
            createExaminationRequest(from: examination2, DPJPId: DPJPId, useFirstExamGoal: true)
        ]
    }
    
    private func buildSingleExaminationRequest(DPJPId: String) throws -> [ExaminationRequest] {
        guard examination.goal != nil && examination.preparationType != nil && !examination.slideId.isEmpty else {
            throw ExaminationError.examinationIncomplete
        }
        
        return [createExaminationRequest(from: examination, DPJPId: DPJPId)]
    }
    
    private func createExaminationRequest(from exam: Examination, DPJPId: String, useFirstExamGoal: Bool = false) -> ExaminationRequest {
        let picId = examinationPICId.isEmpty ? selectedPIC : examinationPICId
        return ExaminationRequest(
            goal: useFirstExamGoal ? examination.goal : exam.goal,
            preparationType: exam.preparationType,
            slideId: exam.slideId.trimmingCharacters(in: .whitespacesAndNewlines),
            examinationDate: exam.examinationDate,
            PIC: picId,
            DPJP: DPJPId,
            examinationPlanDate: exam.examinationPlanDate
        )
    }
    
    @MainActor
    private func resolvedServerPatientIdForSubmit() async throws -> String {
        let generation = AuthSessionManager.authenticationSessionGeneration
        let preferred = savedPatientId.isEmpty ? examinationPatientId : savedPatientId
        let trimmed = preferred.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ExaminationError.missingPatientId
        }

        let persisted = try await repository.ensurePatientOnServer(
            draft: patient,
            preferredId: trimmed
        )
        guard !Task.isCancelled, generation == AuthSessionManager.authenticationSessionGeneration else { throw CancellationError() }
        applyPersistedPatient(persisted)
        return persisted.id.lowercased()
    }
    
    private func validateExaminationResponse(_ response: ExaminationDataResponse, expectedCount: Int) throws {
        let createdExaminations = response.examinations
        
        guard createdExaminations.count == expectedCount else {
            throw ExaminationError.incompleteCreation
        }
        
        guard createdExaminations.allSatisfy({ !$0.id.isEmpty && !$0.slideId.isEmpty }) else {
            throw ExaminationError.invalidData
        }
    }
    
    private func showError(_ message: String) {
        isError = true
        errorMessage = message
    }
}

// MARK: - Examination Error Handling
private enum ExaminationError: Error {
    case firstExamIncomplete
    case secondExamIncomplete
    case duplicateSlideIds
    case examinationIncomplete
    case missingPatientId
    case incompleteCreation
    case invalidData
    
    var message: String {
        switch self {
        case .missingPatientId:
            return AppTextTaskAssignInputExam.errorMessageFailedToGetResponse
        case .firstExamIncomplete:
            return AppTextTaskAssignInputExam.warningFirstExamShouldBeFilled
        case .secondExamIncomplete:
            return AppTextTaskAssignInputExam.warningSecondExamShouldBeFilled
        case .duplicateSlideIds:
            return AppTextTaskAssignInputExam.warningSlideIDsMustBeDifferent
        case .examinationIncomplete:
            return AppTextTaskAssignInputExam.warningExaminationMustBeFilled
        case .incompleteCreation:
            return AppTextTaskAssignInputExam.errorMessageNotAllExamsCreated
        case .invalidData:
            return AppTextTaskAssignInputExam.errorMessageExamsContainInvalidData
        }
    }
}

// MARK: - Form Handling & UI Actions
extension TaskAssignmentFlowCoordinator {
    // MARK: - Form Handlers
    func handleGoalChange() {
        let goalType: ExamGoalType = goalString == AppMedical.Examination.goalFollowUp ? .TREATMENT : .SCREENING
        examination.goal = goalType
        examination2.goal = goalType
        Logger.debug("Examination goal updated to: \(goalType.rawValue)", category: .taskAssignment)
    }
    
    func handleFirstSlideTypeChange() {
        examination.preparationType = mapPreparationType(from: typeString)
        Logger.debug("First slide preparation type updated to: \(examination.preparationType?.rawValue ?? "nil")", category: .taskAssignment)
    }
    
    func handleSecondSlideTypeChange() {
        examination2.preparationType = mapPreparationType(from: typeString2)
        Logger.debug("Second slide preparation type updated to: \(examination2.preparationType?.rawValue ?? "nil")", category: .taskAssignment)
    }
    
    private func mapPreparationType(from string: String) -> ExamPreparationType {
        return string == AppMedical.Examination.preparationTypeMorning ? .SP : .SPS
    }
    
    // MARK: - UI Actions
    func showSubmitPopup() {
        resetErrorState()
        specimenValidationAttempted = true
        guard validateSpecimenStepBeforeProceed() else { return }
        isSubmitPopUpVisible = true
        Logger.info("Submit popup displayed", category: .taskAssignment)
    }
    
    func hideSubmitPopup() {
        resetErrorState()
        isSubmitPopUpVisible = false
        Logger.info("Submit popup hidden - returning to examination", category: .taskAssignment)
    }
    
    // MARK: - Patient Form Handlers
    func handleDateOfBirthChange() {
        patient.DoB = selectedDoB
        updatePatientFieldError(.dateOfBirth)
    }

    func handleGenderChange() {
        switch selectedSex {
        case AppPatient.Gender.female: patient.sex = .FEMALE
        case AppPatient.Gender.male: patient.sex = .MALE
        default: patient.sex = .UNKNOWN
        }
        updatePatientFieldError(.sex)
    }

    func handleBPJSNumberChange() {
        let value = BPJSnumber.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.BPJS = value.isEmpty ? nil : value
        updatePatientFieldError(.bpjs)
    }

    func handleNIKChange() { updatePatientFieldError(.nik) }
    func handleMedicalRecordNumberChange() { updatePatientFieldError(.medicalRecordNumber) }
    
    func handlePICChange() {
        _ = validationManager.validateRequired(selectedPIC, fieldName: ValidationFieldName.userRole.fieldName)
        Logger.debug("PIC selection updated", category: .taskAssignment)
    }
    
    func handlePatientSelectionChange() {
        _ = validationManager.validateRequired(
            patientSelection?.valueForBinding ?? AppValue.empty,
            fieldName: ValidationFieldName.patientName.fieldName
        )
        Logger.debug("Patient selection updated", category: .taskAssignment)
    }
}

// MARK: - Model Extensions
extension Patient {
    static var empty: Patient {
        return Patient(
            name: AppValue.empty,
            NIK: AppValue.empty,
            DoB: nil,
            sex: .UNKNOWN
        )
    }
}

extension User {
    static var empty: User {
        return User(id: AppValue.empty, name: AppValue.empty, role: .ADMIN)
    }
}

extension Examination {
    static var empty: Examination {
        return Examination(
            goal: nil,
            preparationType: nil,
            slideId: AppValue.empty,
            recordVideo: nil,
            examinationDate: Date(),
            examinationPlanDate: Date(),
            statusExamination: .NOTSTARTED
        )
    }
}

