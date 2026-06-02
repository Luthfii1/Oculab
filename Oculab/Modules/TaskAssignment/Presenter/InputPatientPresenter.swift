//
//  InputPatientPresenter.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 07/11/24.
//

import Foundation
import SwiftUI

class InputPatientPresenter: ObservableObject {
    // MARK: - Dependencies
    private let interactor: InputPatientInteractor
    @ObservedObject private var validationManager = ValidationManager.shared
    
    // MARK: - Published Properties
    @Published var selectedPIC: String = AppValue.empty {
        didSet {
            handlePICChange()
        }
    }
    @Published var selectedPatient: String = AppValue.empty {
        didSet {
            handlePatientSelectionChange()
        }
    }
    
    // MARK: - UI State
    @Published var isAddingNewPatient: Bool = false
    @Published var isError: Bool = false
    @Published var errorMessage: String = AppValue.empty
    @Published var isUserLoading = false
    @Published var isPatientLoading = false
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
    init(interactor: InputPatientInteractor = InputPatientInteractor()) {
        self.interactor = interactor
    }
    
    // MARK: - Computed Properties
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
    
    func canProceedToSpecimen(userRole: RolesType, businessModel: BusinessModelType) -> Bool {
        // Clear all errors before validation
        validationManager.clearAllErrors()
        
        // Validate required dropdowns
        let validPIC = validationManager.validateRequired(selectedPIC, fieldName: ValidationFieldName.userRole.fieldName)
        let validPatientSelection = validationManager.validateRequired(selectedPatient, fieldName: ValidationFieldName.patientName.fieldName)
        
        // Validate patient data using ValidationManager
        let validNIK = validationManager.validateNIK(patient.NIK, fieldName: ValidationFieldName.patientNIK.fieldName)
        let validGender = validationManager.validateRequired(selectedSex, fieldName: ValidationFieldName.patientGender.fieldName)
        
        // Validate Date of Birth
        let validDoB = validationManager.validateDate(
            patient.DoB, 
            fieldName: ValidationFieldName.patientDateOfBirth.fieldName,
            allowFuture: false,
            allowPast: true
        )
        
        // Validate BPJS (optional but if provided should be valid)
        var validBPJS = true
        if !BPJSnumber.isEmpty {
            validBPJS = validationManager.validateWithRules(
                BPJSnumber, 
                fieldName: ValidationFieldName.patientBPJS.fieldName, 
                rules: [
                    .numbersOnly(),
                    .minLength(11),
                    .maxLength(13)
                ]
            )
        }
        
        let allValid = validPIC && validPatientSelection && validNIK && validGender && validDoB && validBPJS
        
        Logger.debug("Form validation - PIC: \(validPIC), Patient: \(validPatientSelection), NIK: \(validNIK), Gender: \(validGender), DoB: \(validDoB), BPJS: \(validBPJS), Overall: \(allValid)", category: .taskAssignment)
        
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
extension InputPatientPresenter {
    @MainActor
    func getAllUser() async {
        isUserLoading = true
        defer { isUserLoading = false }
        
        do {
            let users = try await interactor.getAllUser()
            picName = users.map { ($0.name, $0._id) }
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
            let patients = try await interactor.getAllPatient()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = AppConstants.PatientUI.dateFormat
            
            patientNameDoB = patients.map { patient in
                let formattedDoB = patient.DoB.map { dateFormatter.string(from: $0) } ?? AppValue.empty
                return (patient.name + AppValue.space + formattedDoB, patient._id)
            }
        } catch {
            if isEmptyPatientListError(error) {
                patientNameDoB = []
                return
            }
            errorMessage = ErrorHandler.shared.handleError(error, context: .generic)
            isError = true
        }
    }

    @MainActor
    func getPatientById(patientId: String) async {
        guard isExistingPatientSelection(patientId) else {
            prepareNewPatientSelection(name: patientId)
            return
        }

        isPatientLoading = true
        defer { isPatientLoading = false }
        
        do {
            let patient = try await interactor.getPatientById(patientId: patientId)
            self.patient = patient
            self.patientFound = true
        } catch {
            clearForm()
            errorMessage = ErrorHandler.shared.handleError(error, context: .generic)
            isError = true
        }
    }

    func isExistingPatientSelection(_ patientId: String) -> Bool {
        patientNameDoB.contains { $0.1 == patientId }
    }

    @MainActor
    func prepareNewPatientSelection(name: String) {
        patientFound = false
        patient = Patient.empty
        patient.name = name
        selectedDoB = Date()
        selectedSex = AppValue.empty
        BPJSnumber = AppValue.empty
        validationManager.clearAllErrors()
    }

    private func isEmptyPatientListError(_ error: Error) -> Bool {
        guard case let NetworkError.apiError(apiResponse, _) = error else { return false }
        return apiResponse.data.errorType == "RESOURCE_NOT_FOUND"
            && apiResponse.data.description == "No patients found"
    }

    @MainActor
    func getUserById(userId: String) async {
        isUserLoading = true
        defer { isUserLoading = false }
        
        do {
            let user = try await interactor.getUserById(userId: userId)
            self.pic = user
        } catch {
            _ = ErrorHandler.shared.handleError(error, context: .generic)
            isError = true
        }
    }
    
    @MainActor
    func addNewPatient() async -> Bool {
        Logger.debug("Adding new patient", category: .taskAssignment)

        do {
            patient.name = selectedPatient
            let response = try await interactor.addNewPatient(patient: patient)
            patient = response
            return true
        } catch {
            errorMessage = ErrorHandler.shared.handleError(error, context: .patientManagement)
            isError = true
        }
        return false
    }
}

// MARK: - Patient Management
extension InputPatientPresenter {
    func clearForm() {
        patientFound = false
        patient = Patient.empty
        selectedDoB = Date()
        selectedSex = AppValue.empty
        BPJSnumber = AppValue.empty
        validationManager.clearAllErrors()
    }
    
    @MainActor
    func newExam() {
        Task {
            if !patientFound {
                let success = await addNewPatient()
                if success {
                    navigateToNewExam()
                } else {
                    Logger.error("Failed to add new patient", category: .taskAssignment)
                }
            } else {
                Logger.debug("Patient already exists, proceeding to examination", category: .taskAssignment)
                navigateToNewExam()
            }
        }
    }
    
    private func navigateToNewExam() {
        Router.shared.navigateTo(.newExam(patientId: patient._id, picId: pic._id))
    }
    
    func setupExaminationData(selectedPIC: String, selectedPatient: String) {
        Task {
            await getPatientById(patientId: selectedPatient)
            await getUserById(userId: selectedPIC)
            Logger.info("Examination data loaded", category: .taskAssignment)
        }
    }
}

// MARK: - Examination Submission
extension InputPatientPresenter {
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
            let examinationsToSend = try buildExaminationRequests(DPJPId: DPJPId)
            let response = try await submitExaminationRequests(examinationsToSend)
            try validateExaminationResponse(response, expectedCount: examinationsToSend.count)
            
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
        return ExaminationRequest(
            _id: exam._id,
            goal: useFirstExamGoal ? examination.goal : exam.goal,
            preparationType: exam.preparationType,
            slideId: exam.slideId,
            examinationDate: exam.examinationDate,
            PIC: pic._id,
            DPJP: DPJPId,
            examinationPlanDate: exam.examinationPlanDate
        )
    }
    
    private func submitExaminationRequests(_ requests: [ExaminationRequest]) async throws -> ExaminationDataResponse {
        return try await interactor.addNewExamination(patientId: patient._id, examinations: requests)
    }
    
    private func validateExaminationResponse(_ response: ExaminationDataResponse, expectedCount: Int) throws {
        let createdExaminations = response.examinations
        
        guard createdExaminations.count == expectedCount else {
            throw ExaminationError.incompleteCreation
        }
        
        guard createdExaminations.allSatisfy({ !$0._id.isEmpty && !$0.slideId.isEmpty }) else {
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
    case incompleteCreation
    case invalidData
    
    var message: String {
        switch self {
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
extension InputPatientPresenter {
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
        _ = validationManager.validateRequired(selectedPatient, fieldName: ValidationFieldName.patientName.fieldName)
        Logger.debug("Patient selection updated", category: .taskAssignment)
    }
}

// MARK: - Model Extensions
extension Patient {
    static var empty: Patient {
        return Patient(
            _id: UUID().uuidString.lowercased(),
            name: AppValue.empty,
            NIK: AppValue.empty,
            DoB: Date(),
            sex: .UNKNOWN
        )
    }
}

extension User {
    static var empty: User {
        return User(_id: AppValue.empty, name: AppValue.empty, role: .ADMIN)
    }
}

extension Examination {
    static var empty: Examination {
        return Examination(
            _id: UUID().uuidString.lowercased(),
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

struct ExaminationRequest: Encodable {
    var _id: String?
    var goal: ExamGoalType?
    var preparationType: ExamPreparationType?
    var slideId: String?
    var examinationDate: Date?
    var PIC: String?
    var DPJP: String?
    var examinationPlanDate: Date?

    enum CodingKeys: CodingKey {
        case _id
        case goal
        case preparationType
        case slideId
        case examinationDate
        case PIC
        case DPJP
        case examinationPlanDate
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(_id, forKey: ._id)
        try container.encode(goal, forKey: .goal)
        try container.encode(preparationType, forKey: .preparationType)
        try container.encode(slideId, forKey: .slideId)
        try container.encode(PIC, forKey: .PIC)
        try container.encode(DPJP, forKey: .DPJP)

        if let examinationDate = examinationDate {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateString = dateFormatter.string(from: examinationDate)
            try container.encode(dateString, forKey: .examinationDate)
        }

        if let examinationPlanDate = examinationPlanDate {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateString = dateFormatter.string(from: examinationPlanDate)
            try container.encode(dateString, forKey: .examinationPlanDate)
        }
    }
}
