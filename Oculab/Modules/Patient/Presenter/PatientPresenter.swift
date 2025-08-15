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
    var interactor: PatientInteractor? = PatientInteractor()
    
    // MARK: - Form Validation
    var formValidation: FormValidationViewModel
    
    init() {
        self.formValidation = FormValidationViewModel()
    }
    
    // MARK: - UI State
    var isPatientLoading = false
    var patientNameDoB: [(String, String)] = []
    var searchText: String = AppValue.empty
    var filteredPatientNameDoB: [(String, String)] = []
    
    // MARK: - Patient Data with Validation
    var patient: Patient = .init(
        _id: UUID().uuidString.lowercased(),
        name: AppValue.empty,
        NIK: AppValue.empty,
        DoB: Date(),
        sex: .UNKNOWN
    ) {
        didSet {
            validatePatientFields()
        }
    }
    
    var selectedSex: String = AppValue.empty
    var BPJSnumber: String = AppValue.empty {
        didSet {
            validateBPJSField()
        }
    }
    var selectedDoB: Date = Date()
    
    // MARK: - Validation Error States
    var nameError: String = AppValue.empty
    var nikError: String = AppValue.empty
    var bpjsError: String = AppValue.empty
    
    // MARK: - Other States
    var examinationList: [ExaminationResultCardData] = []
    var isLoadingPatient: Bool = false
    var isLoadingExaminations: Bool = false
    var errorMessage: String?
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        return validatePatientForm() && !isPatientLoading
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
            nameError = isValid ? AppValue.empty : (ValidationManager.shared.getError(for: ValidationFieldName.patientName.rawValue) ?? AppValue.empty)
        } else {
            nameError = AppValue.empty
            ValidationManager.shared.clearError(for: ValidationFieldName.patientName.rawValue)
        }
    }
    
    private func validateNIKField() {
        if !patient.NIK.isEmpty {
            let isValid = ValidationManager.shared.validateNIK(patient.NIK, fieldName: ValidationFieldName.patientNIK.rawValue)
            nikError = isValid ? AppValue.empty : (ValidationManager.shared.getError(for: ValidationFieldName.patientNIK.rawValue) ?? AppValue.empty)
        } else {
            nikError = AppValue.empty
            ValidationManager.shared.clearError(for: ValidationFieldName.patientNIK.rawValue)
        }
    }
    
    private func validateBPJSField() {
        if !BPJSnumber.isEmpty {
            let isValid = ValidationManager.shared.validateWithRules(BPJSnumber, fieldName: ValidationFieldName.patientBPJS.rawValue, rules: [
                .numbersOnly(),
                .minLength(13),
                .maxLength(13)
            ])
            bpjsError = isValid ? AppValue.empty : (ValidationManager.shared.getError(for: ValidationFieldName.patientBPJS.rawValue) ?? AppValue.empty)
        } else {
            bpjsError = AppValue.empty
            ValidationManager.shared.clearError(for: ValidationFieldName.patientBPJS.rawValue)
        }
    }
}

// MARK: - Patient Data Management
extension PatientPresenter {
    @MainActor
    func addNewPatientWithValidation() async {
        guard validatePatientForm() else {
            print("🔘 Patient form validation failed")
            return
        }
        
        formValidation.clearAllErrors()
        await addNewPatient()
    }
    
    @MainActor
    func updatePatientWithValidation() async {
        guard validatePatientForm() else {
            print("🔘 Patient form validation failed")
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
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd/MM/yyyy"

                patientNameDoB.removeAll()
                for patient in response {
                    let formattedDoB = patient.DoB.map { dateFormatter.string(from: $0) } ?? AppValue.empty
                    patientNameDoB.append((patient.name + String(formattedDoB), patient._id))
                }
                filterPatients()
            }
        } catch {
            errorMessage = ErrorHandler.shared.handleError(error)
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
                self.BPJSnumber = fetchedPatient.BPJS ?? AppValue.empty
                self.selectedDoB = fetchedPatient.DoB ?? Date()
                
                switch fetchedPatient.sex {
                case .FEMALE:
                    self.selectedSex = AppPatient.Gender.female
                case .MALE:
                    self.selectedSex = AppPatient.Gender.male
                default:
                    self.selectedSex = AppValue.empty
                }
            }
        } catch {
            errorMessage = ErrorHandler.shared.handleError(error)
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
                Router.shared.navigateBack()
            }
        } catch {
            errorMessage = ErrorHandler.shared.handleError(error)
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
                Router.shared.navigateBack()
            }
        } catch {
            errorMessage = ErrorHandler.shared.handleError(error)
        }
    }
}

// MARK: - Search and Filter Operations
extension PatientPresenter {
    func searchPatients() {
        filterPatients()
    }
    
    func clearSearch() {
        searchText = AppValue.empty
        filterPatients()
    }
    
    private func filterPatients() {
        if searchText.isEmpty {
            filteredPatientNameDoB = patientNameDoB
        } else {
            filteredPatientNameDoB = patientNameDoB.filter { nameWithDoB, _ in
                let name = nameWithDoB.components(separatedBy: " (").first ?? AppValue.empty
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
            print("Fetching examinations for patient: \(patientId)")
            let response = try await interactor?.getAllExamByPatientId(patientId: patientId)
            
            if let examinations = response {
                print("Received \(examinations.count) examinations")
                self.examinationList = examinations
            }

        } catch {
            errorMessage = ErrorHandler.shared.handleError(error)
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
        guard let date = date else { return AppValue.empty }
        let formatter = DateFormatter()
        formatter.locale = Locale.current // Use current locale for localization
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
    
    func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current // Use current locale for localization
        formatter.dateFormat = "dd MMMM yyyy HH:mm"
        return formatter.string(from: date)
    }
}
