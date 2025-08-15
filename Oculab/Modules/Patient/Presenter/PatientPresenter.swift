//
//  PatientPresenter.swift
//  Oculab
//
//  Created by Risa on 30/05/25.
//

import Foundation
import SwiftUI
import Observation

@Observable
class PatientPresenter {
    // MARK: - Dependencies
    private var interactor: PatientInteractor? = PatientInteractor()
    
    // MARK: - Form Validation
    var formValidation: FormValidationViewModel
    
    // MARK: - Initialization
    init() {
        self.formValidation = FormValidationViewModel()
    }
    
    // MARK: - UI State
    var isPatientLoading = false
    var patientNameDoB: [(String, String)] = []
    var searchText: String = AppConstants.PatientUI.defaultEmptyValue
    var filteredPatientNameDoB: [(String, String)] = []
    
    // MARK: - Patient Data with Validation
    var patient: Patient = .init(
        _id: UUID().uuidString.lowercased(),
        name: AppConstants.PatientUI.defaultEmptyValue,
        NIK: AppConstants.PatientUI.defaultEmptyValue,
        DoB: Date(),
        sex: .UNKNOWN
    ) {
        didSet {
            validatePatientFields()
        }
    }
    
    var selectedSex: String = AppConstants.PatientUI.defaultEmptyValue
    var BPJSnumber: String = AppConstants.PatientUI.defaultEmptyValue {
        didSet {
            validateBPJSField()
        }
    }
    var selectedDoB: Date = Date()
    
    // MARK: - Validation Error States
    var nameError: String = AppConstants.PatientUI.defaultEmptyValue
    var nikError: String = AppConstants.PatientUI.defaultEmptyValue
    var bpjsError: String = AppConstants.PatientUI.defaultEmptyValue
    
    // MARK: - Other States
    var examinationList: [ExaminationResultCardData] = []
    var isLoadingPatient: Bool = false
    var isLoadingExaminations: Bool = false
    var errorMessage: String?
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        return validatePatientForm() && !isPatientLoading
    }
    
    // MARK: - Form View Properties
    var buttonTitle: String {
        isAddingNewPatient ? AppTextPatientCompCard.buttonCreatePatient : AppTextPatientCompCard.buttonSavePatient
    }
    
    var buttonIcon: String {
        isAddingNewPatient ? AppIcon.add : AppIcon.checkmark
    }
    
    var navigationTitle: String {
        isAddingNewPatient ? AppTextPatientForm.newPatientNavigationTitle : AppTextPatientForm.editPatientNavigationTitle
    }
    
    private var isAddingNewPatient: Bool {
        return patient._id.isEmpty || patient.name.isEmpty
    }
}

// MARK: - Form Management
extension PatientPresenter {
    func setupForm(patientId: String?) {
        guard let patientId = patientId else { return }
        Task {
            await getPatientById(patientId: patientId)
        }
    }
    
    func handleFormSubmission() async {
        if isAddingNewPatient {
            await addNewPatientWithValidation()
        } else {
            await updatePatientWithValidation()
        }
    }
    
    // MARK: - Field Change Handlers
    func handleDateOfBirthChange() {
        patient.DoB = selectedDoB
        Logger.debug("Date of birth updated", category: .patient)
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
        Logger.debug("Gender updated to: \(patient.sex)", category: .patient)
    }
    
    func handleBPJSChange() {
        patient.BPJS = BPJSnumber.isEmpty ? nil : BPJSnumber
        Logger.debug("BPJS number updated", category: .patient)
    }

    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Form Validation
extension PatientPresenter {
    func validatePatientForm() -> Bool {
        return formValidation.validatePatientForm(
            name: patient.name,
            nik: patient.NIK,
            bpjs: BPJSnumber.isEmpty ? nil : BPJSnumber
        )
    }
    
    private func validatePatientFields() {
        validateNameField()
        validateNIKField()
    }
    
    private func validateNameField() {
        if !patient.name.isEmpty {
            let isValid = ValidationManager.shared.validateName(patient.name, fieldName: ValidationFieldName.patientName.rawValue)
            nameError = isValid ? AppConstants.PatientUI.defaultEmptyValue : (ValidationManager.shared.getError(for: ValidationFieldName.patientName.rawValue) ?? AppConstants.PatientUI.defaultEmptyValue)
        } else {
            nameError = AppConstants.PatientUI.defaultEmptyValue
            ValidationManager.shared.clearError(for: ValidationFieldName.patientName.rawValue)
        }
    }
    
    private func validateNIKField() {
        if !patient.NIK.isEmpty {
            let isValid = ValidationManager.shared.validateNIK(patient.NIK, fieldName: ValidationFieldName.patientNIK.rawValue)
            nikError = isValid ? AppConstants.PatientUI.defaultEmptyValue : (ValidationManager.shared.getError(for: ValidationFieldName.patientNIK.rawValue) ?? AppConstants.PatientUI.defaultEmptyValue)
        } else {
            nikError = AppConstants.PatientUI.defaultEmptyValue
            ValidationManager.shared.clearError(for: ValidationFieldName.patientNIK.rawValue)
        }
    }
    
    private func validateBPJSField() {
        if !BPJSnumber.isEmpty {
            let isValid = ValidationManager.shared.validateWithRules(BPJSnumber, fieldName: ValidationFieldName.patientBPJS.rawValue, rules: [
                .numbersOnly(),
                .minLength(AppConstants.PatientUI.bpjsMinLength),
                .maxLength(AppConstants.PatientUI.bpjsMaxLength)
            ])
            bpjsError = isValid ? AppConstants.PatientUI.defaultEmptyValue : (ValidationManager.shared.getError(for: ValidationFieldName.patientBPJS.rawValue) ?? AppConstants.PatientUI.defaultEmptyValue)
        } else {
            bpjsError = AppConstants.PatientUI.defaultEmptyValue
            ValidationManager.shared.clearError(for: ValidationFieldName.patientBPJS.rawValue)
        }
    }
}

// MARK: - Patient Data Management
extension PatientPresenter {
    @MainActor
    func addNewPatientWithValidation() async {
        guard validatePatientForm() else {
            Logger.warning("Patient form validation failed", category: .patient)
            return
        }
        
        formValidation.clearAllErrors()
        await addNewPatient()
    }
    
    @MainActor
    func updatePatientWithValidation() async {
        guard validatePatientForm() else {
            Logger.warning("Patient form validation failed", category: .patient)
            return
        }
        
        formValidation.clearAllErrors()
        await updatePatient()
    }
    
    @MainActor
    func getAllPatient() async {
        isPatientLoading = true
        defer {
            isPatientLoading = false
        }

        do {
            let response = try await interactor?.getAllPatient()

            if let response {
                patientNameDoB.removeAll()
                for patient in response {
                    let formattedDoB = formatDate(patient.DoB)
                    patientNameDoB.append((patient.name + String(formattedDoB), patient._id))
                }
                filterPatients()
                Logger.info("Successfully fetched \(response.count) patients", category: .patient)
            }
        } catch {
            errorMessage = ErrorHandler.shared.handleError(error)
            Logger.error("Failed to fetch patients: \(error.localizedDescription)", category: .patient)
        }
    }
    
    @MainActor
    func getPatientById(patientId: String) async {
        isPatientLoading = true
        defer {
            isPatientLoading = false
        }

        do {
            let response = try await interactor?.getPatientById(patientId: patientId)

            if let fetchedPatient = response {
                self.patient = fetchedPatient
                self.BPJSnumber = fetchedPatient.BPJS ?? AppConstants.PatientUI.defaultEmptyValue
                self.selectedDoB = fetchedPatient.DoB ?? Date()
                
                switch fetchedPatient.sex {
                case .FEMALE:
                    self.selectedSex = AppPatient.Gender.female
                case .MALE:
                    self.selectedSex = AppPatient.Gender.male
                default:
                    self.selectedSex = AppConstants.PatientUI.defaultEmptyValue
                }
                Logger.info("Successfully fetched patient with ID: \(patientId)", category: .patient)
            }
        } catch {
            errorMessage = ErrorHandler.shared.handleError(error)
            Logger.error("Failed to fetch patient with ID \(patientId): \(error.localizedDescription)", category: .patient)
        }
    }

    @MainActor
    func addNewPatient() async {
        isPatientLoading = true
        defer {
            isPatientLoading = false
        }
        
        patient.DoB = selectedDoB
        patient.BPJS = BPJSnumber.isEmpty ? nil : BPJSnumber
        
        do {
            let response = try await interactor?.addNewPatient(patient: patient)
            if response != nil {
                Logger.info("Successfully added new patient: \(patient.name)", category: .patient)
                Router.shared.navigateBack()
            }
        } catch {
            errorMessage = ErrorHandler.shared.handleError(error)
            Logger.error("Failed to add new patient: \(error.localizedDescription)", category: .patient)
        }
    }
    
    @MainActor
    func updatePatient() async {
        isPatientLoading = true
        defer {
            isPatientLoading = false
        }
        
        patient.DoB = selectedDoB
        patient.BPJS = BPJSnumber.isEmpty ? nil : BPJSnumber
        
        switch selectedSex {
        case AppPatient.Gender.female:
            patient.sex = .FEMALE
        case AppPatient.Gender.male:
            patient.sex = .MALE
        default:
            patient.sex = .UNKNOWN
        }
        
        do {
            let response = try await interactor?.updatePatient(patient: patient, patientId: String(describing: patient._id))

            if let updatedPatient = response {
                self.patient = updatedPatient
                Logger.info("Successfully updated patient: \(patient.name)", category: .patient)
                Router.shared.navigateBack()
            }
        } catch {
            errorMessage = ErrorHandler.shared.handleError(error)
            Logger.error("Failed to update patient: \(error.localizedDescription)", category: .patient)
        }
    }
}

// MARK: - Search and Filter Operations
extension PatientPresenter {
    func searchPatients() {
        filterPatients()
    }
    
    func clearSearch() {
        searchText = AppConstants.PatientUI.defaultEmptyValue
        filterPatients()
    }
    
    private func filterPatients() {
        if searchText.isEmpty {
            filteredPatientNameDoB = patientNameDoB
        } else {
            filteredPatientNameDoB = patientNameDoB.filter { nameWithDoB, _ in
                let name = nameWithDoB.components(separatedBy: " (").first ?? AppConstants.PatientUI.defaultEmptyValue
                return name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Examination Management
extension PatientPresenter {
    @MainActor
    func getExaminationsByPatientId(patientId: String) async {
        isLoadingExaminations = true
        defer { isLoadingExaminations = false }
        
        do {
            Logger.info("Fetching examinations for patient: \(patientId)", category: .patient)
            let response = try await interactor?.getAllExamByPatientId(patientId: patientId)
            
            if let examinations = response {
                Logger.info("Successfully received \(examinations.count) examinations", category: .patient)
                self.examinationList = examinations
            }

        } catch {
            errorMessage = ErrorHandler.shared.handleError(error)
            Logger.error("Failed to fetch examinations for patient \(patientId): \(error.localizedDescription)", category: .patient)
            isLoadingExaminations = false
        }
    }
}

// MARK: - Navigation
extension PatientPresenter {
    func navigateTo(_ destination: Router.Route) {
        Router.shared.navigateTo(destination)
    }
    
    func navigateBack() {
        Router.shared.navigateBack()
    }
}

// MARK: - Helper Methods
extension PatientPresenter {
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return AppConstants.PatientUI.defaultEmptyValue }
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = AppConstants.PatientUI.dateFormat
        return formatter.string(from: date)
    }
    
    func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = AppConstants.PatientUI.dateTimeFormat
        return formatter.string(from: date)
    }
}
