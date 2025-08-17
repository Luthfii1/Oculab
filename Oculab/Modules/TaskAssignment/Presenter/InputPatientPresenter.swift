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
    
    // MARK: - Published Properties
    @Published var selectedPIC: String = AppValue.empty
    @Published var selectedPatient: String = AppValue.empty {
        didSet {
            Logger.debug("Patient selected: \(selectedPatient)", category: .taskAssignment)
        }
    }
    
    // MARK: - UI State
    @Published var isAddingNewPatient: Bool = false
    @Published var isError: Bool = false
    @Published var errorMessage: String = AppValue.empty
    @Published var isUserLoading = false
    @Published var isPatientLoading = false
    @Published var isSubmitPopUpVisible: Bool = false
    
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
        return goalString != AppValue.empty &&
               typeString != AppValue.empty &&
               examination.slideId != AppValue.empty &&
               typeString2 != AppValue.empty &&
               examination2.slideId != AppValue.empty
    }

    private var hasValidPatientData: Bool {
        !(patient.NIK == AppValue.empty || patient.DoB == nil)
    }
    
    private func hasValidPIC(userRole: RolesType, businessModel: BusinessModelType) -> Bool {
        if userRole == .LAB && businessModel == .B2C {
            return selectedPIC != AppValue.empty
        }
        return selectedPIC != AppValue.empty
    }
    
    func canProceedToSpecimen(userRole: RolesType, businessModel: BusinessModelType) -> Bool {
        hasValidPatientData && hasValidPIC(userRole: userRole, businessModel: businessModel)
    }
    
    // MARK: - Helper Methods
    private func updatePatientForm() {
        Logger.info("Patient found - DoB: \(String(describing: patient.DoB)), Sex: \(patient.sex), BPJS: \(String(describing: patient.BPJS))", category: .taskAssignment)
        selectedDoB = patient.DoB ?? Date()
        selectedSex = patient.sex == .MALE ? AppPatient.Gender.male : 
                     patient.sex == .FEMALE ? AppPatient.Gender.female : AppValue.empty
        BPJSnumber = patient.BPJS ?? AppValue.empty
    }
    
    private func resetErrorState() {
        isError = false
        errorMessage = AppValue.empty
    }
    
    private func handleError(_ error: Error, context: ErrorHandler.ErrorContext = .generic) {
        errorMessage = ErrorHandler.shared.handleError(error, context: context)
        isError = true
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
            handleError(error)
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
            handleError(error)
        }
    }

    @MainActor
    func getPatientById(patientId: String) async {
        isPatientLoading = true
        defer { isPatientLoading = false }
        
        do {
            let patient = try await interactor.getPatientById(patientId: patientId)
            self.patient = patient
            self.patientFound = true
        } catch {
            clearForm()
            handleError(error)
        }
    }

    @MainActor
    func getUserById(userId: String) async {
        isUserLoading = true
        defer { isUserLoading = false }
        
        do {
            let user = try await interactor.getUserById(userId: userId)
            self.pic = user
        } catch {
            handleError(error)
        }
    }
    
    @MainActor
    func addNewPatient() async -> Bool {
        Logger.debug("Adding new patient - ID: \(patient._id)", category: .taskAssignment)
        Logger.debug("Patient details: \(patient.name), NIK: \(patient.NIK), BPJS: \(patient.BPJS ?? "None")", category: .taskAssignment)

        do {
            patient.name = selectedPatient
            let response = try await interactor.addNewPatient(patient: patient)
            patient = response
            return true
        } catch {
            handleError(error, context: .patientManagement)
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
            Logger.info("Examination data loaded for patient: \(patient.name)", category: .taskAssignment)
        }
    }
}

// MARK: - Examination Submission
extension InputPatientPresenter {
    @MainActor
    func submitExamination() async {
        guard let DPJPId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            handleError(NSError(domain: "UserAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "User authentication required"]))
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
            handleError(error, context: .examination)
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
        Logger.debug("Patient DoB updated to: \(selectedDoB)", category: .taskAssignment)
    }
    
    func handleGenderChange() {
        switch selectedSex {
        case AppPatient.Gender.female:
            patient.sex = .FEMALE
        case AppPatient.Gender.male:
            patient.sex = .MALE
        default:
            patient.sex = .UNKNOWN
        }
        Logger.debug("Patient gender updated to: \(patient.sex)", category: .taskAssignment)
    }
    
    func handleBPJSNumberChange() {
        patient.BPJS = BPJSnumber
        Logger.debug("Patient BPJS updated to: \(BPJSnumber)", category: .taskAssignment)
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
