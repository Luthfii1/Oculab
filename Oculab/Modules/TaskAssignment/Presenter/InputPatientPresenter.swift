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
    // MARK: - Slide 2 UI Logic
    /// Toggle Slide 2 visibility and clear data if hiding
    func toggleSlide2() {
        if isSlide2Visible {
            isSlide2Visible = false
            examination2 = Examination.empty
            typeString2 = AppValue.empty
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
    @Published var selectedDoB: Date = Date()
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
    }

    var knownPatientIds: Set<String> {
        Set(patientNameDoB.map(\.1))
    }
    
    // MARK: - Computed Properties
    var isInitialLoading: Bool {
        !hasCompletedInitialLoad && (isUserLoading || isPatientLoading)
    }

    var isPatientListEmpty: Bool {
        hasCompletedInitialLoad && patientNameDoB.isEmpty
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

    var isFormValid: Bool {
        // Use ValidationManager for all relevant fields
        let validGoal = validationManager.validateRequired(goalString, fieldName: ValidationFieldName.examinationGoal.fieldName)
        let validType1 = validationManager.validateRequired(typeString, fieldName: ValidationFieldName.slideType1.fieldName)
        let validSlideId1 = validationManager.validateRequired(examination.slideId, fieldName: ValidationFieldName.slideId1.fieldName)

        if isSlide2Visible {
            let validType2 = validationManager.validateRequired(typeString2, fieldName: ValidationFieldName.slideType2.fieldName)
            let validSlideId2 = validationManager.validateRequired(examination2.slideId, fieldName: ValidationFieldName.slideId2.fieldName)
            return validGoal && validType1 && validSlideId1 && validType2 && validSlideId2
        } else {
            return validGoal && validType1 && validSlideId1
        }
    }
    
    /// Read-only check for enabling the proceed button (no error mutation, safe in SwiftUI `body`).
    var isPatientStepReady: Bool {
        let validPIC = validationManager.meetsRequired(selectedPIC)
        let validPatientSelection = validationManager.meetsRequired(
            patientSelection?.valueForBinding ?? AppValue.empty
        )
        let validNIK = validationManager.meetsNIK(patient.NIK)
        let validGender = validationManager.meetsRequired(selectedSex)
        let validDoB = validationManager.meetsDate(
            patient.DoB,
            allowFuture: false,
            allowPast: true
        )
        let validBPJS = validationManager.meetsRules(
            BPJSnumber,
            rules: [.numbersOnly(), .minLength(11), .maxLength(13)]
        )
        return validPIC && validPatientSelection && validNIK && validGender && validDoB && validBPJS
    }

    /// Run on submit only — surfaces field errors and logs once per attempt.
    @discardableResult
    func validatePatientStepBeforeProceed() -> Bool {
        validationManager.clearAllErrors()

        let validPIC = validationManager.validateRequired(
            selectedPIC,
            fieldName: ValidationFieldName.userRole.fieldName
        )
        let validPatientSelection = validationManager.validateRequired(
            patientSelection?.valueForBinding ?? AppValue.empty,
            fieldName: ValidationFieldName.patientName.fieldName
        )
        let validNIK = validationManager.validateNIK(
            patient.NIK,
            fieldName: ValidationFieldName.patientNIK.fieldName
        )
        let validGender = validationManager.validateRequired(
            selectedSex,
            fieldName: ValidationFieldName.patientGender.fieldName
        )
        let validDoB = validationManager.validateDate(
            patient.DoB,
            fieldName: ValidationFieldName.patientDateOfBirth.fieldName,
            allowFuture: false,
            allowPast: true
        )
        var validBPJS = true
        if !BPJSnumber.isEmpty {
            validBPJS = validationManager.validateWithRules(
                BPJSnumber,
                fieldName: ValidationFieldName.patientBPJS.fieldName,
                rules: [.numbersOnly(), .minLength(11), .maxLength(13)]
            )
        }

        let allValid = validPIC && validPatientSelection && validNIK && validGender && validDoB && validBPJS
        Logger.debug(
            "Form validation - PIC: \(validPIC), Patient: \(validPatientSelection), NIK: \(validNIK), Gender: \(validGender), DoB: \(validDoB), BPJS: \(validBPJS), Overall: \(allValid)",
            category: .taskAssignment
        )
        return allValid
    }
    
    // MARK: - Helper Methods
    private func updatePatientForm() {
        Logger.info("Patient record loaded", category: .taskAssignment)
        selectedDoB = patient.DoB ?? Date()
        selectedSex = patient.sex == .MALE ? AppPatient.Gender.male : 
                     patient.sex == .FEMALE ? AppPatient.Gender.female : AppValue.empty
        BPJSnumber = patient.BPJS ?? AppValue.empty
        
        // Trigger validation for all loaded fields
        handleDateOfBirthChange()
        handleGenderChange()
        handleBPJSNumberChange()
        handleNIKChange()
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
        isUserLoading = true
        defer { isUserLoading = false }
        
        do {
            let users = try await repository.fetchPICs()
            picName = users.map { ($0.name, $0.id) }
        } catch {
            errorMessage = ErrorHandler.shared.handleError(error, context: .generic)
            isError = true
        }
    }

    @MainActor
    func getAllPatient() async {
        isPatientLoading = true
        defer { isPatientLoading = false }
        
        do {
            let patients = try await repository.fetchPatients()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = AppConstants.PatientUI.dateFormat
            
            patientNameDoB = patients.map { patient in
                let formattedDoB = patient.DoB.map { dateFormatter.string(from: $0) } ?? AppValue.empty
                return (patient.name + AppValue.space + formattedDoB, patient.id)
            }
        } catch {
            if repository.isEmptyPatientListError(error) {
                patientNameDoB = []
                return
            }
            errorMessage = ErrorHandler.shared.handleError(error, context: .generic)
            isError = true
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
        let trimmedId = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedId.isEmpty else { return }

        isPatientLoading = true
        defer { isPatientLoading = false }

        do {
            let loaded = try await repository.fetchPatient(id: trimmedId)
            patient = loaded
            patientFound = true
            isAddingNewPatient = false
            patientSelection = .existing(patientId: loaded.id)
            savedPatientId = loaded.id
            examinationPatientId = loaded.id
        } catch {
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

        patientFound = false
        isAddingNewPatient = true
        patientSelection = .new(displayName: trimmedName)
        savedPatientId = AppValue.empty
        examinationPatientId = AppValue.empty
        patient = Patient.empty
        patient.name = trimmedName
        selectedDoB = Date()
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
        isUserLoading = true
        defer { isUserLoading = false }
        
        do {
            let user = try await repository.fetchUser(id: userId)
            self.pic = user
        } catch {
            _ = ErrorHandler.shared.handleError(error, context: .generic)
            isError = true
        }
    }
    
    private func applyPersistedPatient(_ persisted: Patient) {
        patient = persisted
        savedPatientId = persisted.id
        examinationPatientId = persisted.id
        patientFound = true
        isAddingNewPatient = false
    }
}

// MARK: - Patient Management
extension TaskAssignmentFlowCoordinator {
    func clearForm() {
        patientFound = false
        isAddingNewPatient = false
        patientSelection = nil
        savedPatientId = AppValue.empty
        examinationPatientId = AppValue.empty
        patient = Patient.empty
        selectedDoB = Date()
        selectedSex = AppValue.empty
        BPJSnumber = AppValue.empty
        validationManager.clearAllErrors()
    }
    
    @MainActor
    func newExam() {
        Task {
            await proceedToSpecimenStep()
        }
    }

    /// Single persistence point before leaving step 1.
    @MainActor
    func proceedToSpecimenStep() async {
        guard !isSavingPatient else { return }
        guard validatePatientStepBeforeProceed() else { return }

        isSavingPatient = true
        defer { isSavingPatient = false }

        do {
            syncPatientNameFromSelection()

            let picId = pic.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? selectedPIC.trimmingCharacters(in: .whitespacesAndNewlines)
                : pic.id.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !picId.isEmpty else { throw TaskAssignmentFlowError.missingPic }

            let preferredId = savedPatientId.isEmpty ? patient.id : savedPatientId
            let persisted = try await repository.ensurePatientOnServer(
                draft: patient,
                preferredId: preferredId
            )
            applyPersistedPatient(persisted)

            examinationPICId = picId
            Router.shared.navigateTo(.newExam(patientId: persisted.id, picId: picId))
        } catch let flowError as TaskAssignmentFlowError {
            errorMessage = flowError.localizedDescription
            isError = true
        } catch {
            errorMessage = ErrorHandler.shared.handleError(error, context: .patientManagement)
            isError = true
        }
    }

    /// Step 2 entry — refresh display names; patient is already persisted.
    @MainActor
    func bootstrapSpecimenStep() async {
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
        guard !isSubmittingExamination else { return }
        isSubmittingExamination = true
        defer { isSubmittingExamination = false }

        guard let DPJPId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            errorMessage = AppTextTaskAssignInputExam.errorMessageFailedToGetResponse
            isError = true
            Logger.error("Submit failed: missing DPJP user id in UserDefaults", category: .taskAssignment)
            return
        }
        
        do {
            let patientId = try await resolvedServerPatientIdForSubmit()
            let examinationsToSend = try buildExaminationRequests(DPJPId: DPJPId)
            let response = try await repository.createExaminations(
                patientId: patientId,
                examinations: examinationsToSend
            )
            try validateExaminationResponse(response, expectedCount: examinationsToSend.count)

            Router.shared.endTaskAssignmentFlow()
            Router.shared.popToRoot()
        } catch let error as ExaminationError {
            showError(error.message)
        } catch {
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
        
        guard examination.slideId != examination2.slideId else {
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
        let picId = pic.id.isEmpty ? examinationPICId : pic.id
        return ExaminationRequest(
            goal: useFirstExamGoal ? examination.goal : exam.goal,
            preparationType: exam.preparationType,
            slideId: exam.slideId,
            examinationDate: exam.examinationDate,
            PIC: picId,
            DPJP: DPJPId,
            examinationPlanDate: exam.examinationPlanDate
        )
    }
    
    @MainActor
    private func resolvedServerPatientIdForSubmit() async throws -> String {
        let preferred = savedPatientId.isEmpty ? examinationPatientId : savedPatientId
        let trimmed = preferred.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ExaminationError.missingPatientId
        }

        let persisted = try await repository.ensurePatientOnServer(
            draft: patient,
            preferredId: trimmed
        )
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
        isSubmitPopUpVisible = true
        Logger.info("Submit popup displayed", category: .taskAssignment)
    }
    
    func hideSubmitPopup() {
        isSubmitPopUpVisible = false
        Logger.info("Submit popup hidden - returning to examination", category: .taskAssignment)
    }
    
    // MARK: - Patient Form Handlers
    func handleDateOfBirthChange() {
        patient.DoB = selectedDoB
        // Validate Date of Birth in real-time
        _ = validationManager.validateDate(
            patient.DoB, 
            fieldName: ValidationFieldName.patientDateOfBirth.fieldName,
            allowFuture: false,
            allowPast: true
        )
        Logger.debug("Patient DoB updated", category: .taskAssignment)
    }
    
    func handleGenderChange() {
        switch selectedSex {
        case AppPatient.Gender.female:
            patient.sex = .FEMALE
        case AppPatient.Gender.male:
            patient.sex = .MALE
        default:
            patient.sex = .MALE // Default fallback
        }
        // Validate Gender in real-time
        _ = validationManager.validateRequired(selectedSex, fieldName: ValidationFieldName.patientGender.fieldName)
        Logger.debug("Patient gender updated", category: .taskAssignment)
    }
    
    func handleBPJSNumberChange() {
        patient.BPJS = BPJSnumber
        // Validate BPJS in real-time (only if not empty)
        if !BPJSnumber.isEmpty {
            _ = validationManager.validateWithRules(
                BPJSnumber, 
                fieldName: ValidationFieldName.patientBPJS.fieldName, 
                rules: [
                    .numbersOnly(),
                    .minLength(11),
                    .maxLength(13)
                ]
            )
        } else {
            validationManager.clearError(for: ValidationFieldName.patientBPJS.fieldName)
        }
        Logger.debug("Patient BPJS updated", category: .taskAssignment)
    }
    
    func handleNIKChange() {
        // NIK validation is already handled by ValidatedTextField
        // Just trigger validation update for button state
        Logger.debug("Patient NIK updated", category: .taskAssignment)
    }
    
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
            DoB: Date(),
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

