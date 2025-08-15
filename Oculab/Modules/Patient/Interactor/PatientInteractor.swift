//
//  PatientInteractor.swift
//  Oculab
//
//  Created by Risa on 30/05/25.
//

import Foundation

class PatientInteractor: ObservableObject {
    // MARK: - Dependencies
    private let networkService: NetworkServiceProtocol

    // MARK: - API Endpoints
    private struct APIEndpoints {
        static let getAllPatients = API.BE + "/patient/get-all-patients/"
        static let getPatientById = API.BE + "/patient/get-patient-by-id/"
        static let getAllExamByPatientId = API.BE + "/examination/get-examination-card-by-patient/"
        static let createPatient = API.BE + "/patient/create-new-patient/"
        static let updatePatient = API.BE + "/patient/update-data/"
    }
    
    // MARK: - Initialization
    init(networkService: NetworkServiceProtocol = AlamofireNetworkService()) {
        self.networkService = networkService
    }
    
    // MARK: - Patient Data Operations
    func getAllPatient() async throws -> [Patient] {
        let userId = try getUserId()
        
        let response: APIResponse<[Patient]> = try await networkService
            .get(urlString: APIEndpoints.getAllPatients + userId.lowercased(), headers: nil)

        Logger.info("Successfully fetched all patients", category: .patient)
        return response.data
    }
    
    func getPatientById(patientId: String) async throws -> Patient {
        let response: APIResponse<Patient> = try await networkService
            .get(urlString: APIEndpoints.getPatientById + patientId.lowercased(), headers: nil)

        Logger.info("Successfully fetched patient with ID: \(patientId)", category: .patient)
        return response.data
    }
    
    func getAllExamByPatientId(patientId: String) async throws -> [ExaminationResultCardData] {
        let response: APIResponse<[ExaminationResultCardData]> = try await networkService
            .get(urlString: APIEndpoints.getAllExamByPatientId + patientId, headers: nil)
        
        Logger.info("Successfully fetched examinations for patient: \(patientId)", category: .patient)
        return response.data
    }
    
    func addNewPatient(patient: Patient) async throws -> Patient {
        let adminUserId = try getUserId()
        
        let response: APIResponse<Patient> = try await networkService.post(
            urlString: APIEndpoints.createPatient + adminUserId.lowercased(),
            headers: nil,
            body: patient
        )

        Logger.info("Successfully created new patient: \(patient.name)", category: .patient)
        return response.data
    }
    
    func updatePatient(patient: Patient, patientId: String) async throws -> Patient {
        let response: APIResponse<Patient> = try await networkService.update(
            urlString: APIEndpoints.updatePatient + patientId.lowercased(),
            headers: nil,
            body: patient
        )

        Logger.info("Successfully updated patient: \(patient.name)", category: .patient)
        return response.data
    }
}

// MARK: - Helper Methods
extension PatientInteractor {
    private func getUserId() throws -> String {
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            Logger.error("User ID not found in UserDefaults", category: .patient)
            throw NSError(domain: "UserIdNotFound", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "User ID not found in storage"
            ])
        }
        return userId
    }
}
