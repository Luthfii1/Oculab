//
//  PatientPresenter.swift
//  Oculab
//
//  Created by Risa on 30/05/25.
//

import Foundation
import SwiftUI

class PatientPresenter: ObservableObject {
    var interactor: PatientInteractor? = PatientInteractor()
    
    @Published var isPatientLoading = false
    @Published var patientNameDoB: [(String, String)] = []
    @Published var searchText: String = ""
    @Published var filteredPatientNameDoB: [(String, String)] = []
    
    @Published var patient: Patient = .init(
        _id: UUID().uuidString.lowercased(),
        name: "",
        NIK: "",
        DoB: Date(),
        sex: .UNKNOWN
    )
    
    @Published var selectedSex: String = ""
    @Published var BPJSnumber: String = ""
    @Published var selectedDoB: Date = Date()
    
    @Published var examinationList: [ExaminationResultCardData] = []
    @Published var isLoadingPatient: Bool = false
    @Published var isLoadingExaminations: Bool = false
    @Published var errorMessage: String?
    
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
                    let formattedDoB = patient.DoB.map { dateFormatter.string(from: $0) } ?? ""
                    patientNameDoB.append((patient.name + " (\(formattedDoB))", patient._id))
                }
                filterPatients()
            }
        } catch {
            switch error {
            case let NetworkError.apiError(apiResponse):
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")

            case let NetworkError.networkError(message):
                print("Network error: \(message)")

            default:
                print("Unknown error: \(error.localizedDescription)")
            }
        }
    }
    
    func searchPatients() {
        filterPatients()
    }
    
    func clearSearch() {
        searchText = ""
        filterPatients()
    }
    
    private func filterPatients() {
        if searchText.isEmpty {
            filteredPatientNameDoB = patientNameDoB
        } else {
            filteredPatientNameDoB = patientNameDoB.filter { nameWithDoB, _ in
                let name = nameWithDoB.components(separatedBy: " (").first ?? ""
                return name.localizedCaseInsensitiveContains(searchText)
            }
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
                self.BPJSnumber = fetchedPatient.BPJS ?? ""
                self.selectedDoB = fetchedPatient.DoB ?? Date()
                
                switch fetchedPatient.sex {
                case .FEMALE:
                    self.selectedSex = "Perempuan"
                case .MALE:
                    self.selectedSex = "Laki-laki"
                default:
                    self.selectedSex = ""
                }
            }
        } catch {
            switch error {
            case let NetworkError.apiError(apiResponse):
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")

            case let NetworkError.networkError(message):
                print("Network error: \(message)")

            default:
                print("Unknown error: \(error.localizedDescription)")
            }
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
            switch error {
            case let NetworkError.apiError(apiResponse):
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")
                errorMessage = apiResponse.data.description

            case let NetworkError.networkError(message):
                print("Network error: \(message)")
                errorMessage = message

            default:
                print("Unknown error: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
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
        case "Perempuan":
            patient.sex = .FEMALE
        case "Laki-laki":
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
            switch error {
            case let NetworkError.apiError(apiResponse):
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")
                errorMessage = apiResponse.data.description

            case let NetworkError.networkError(message):
                print("Network error: \(message)")
                errorMessage = message

            default:
                print("Unknown error: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }
    
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
            switch error {
            case let NetworkError.apiError(apiResponse):
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")

            case let NetworkError.networkError(message):
                print("Network error: \(message)")

            default:
                print("Unknown error: \(error.localizedDescription)")
            }
        }
    }
    
    func navigateTo(_ destination: Router.Route) {
        Router.shared.navigateTo(destination)
    }
    
    func navigateBack() {
        Router.shared.navigateBack()
    }
    
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
    
    func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

}
