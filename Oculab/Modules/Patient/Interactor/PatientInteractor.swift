//
//  PatientInteractor.swift
//  Oculab
//
//  Created by Risa on 30/05/25.
//

import Foundation

class PatientInteractor: ObservableObject {
    private let networkService: NetworkService

    init(networkService: NetworkService = AlamofireNetworkService()) {
        self.networkService = networkService
    }
    
    private let apiGetAllPatient = API.BE + "/patient/get-all-patients/"
    let urlGetDataPatient = API.BE + "/patient/get-patient-by-id/"
    let urlGetAllExamByPatientId = API.BE + "/examination/get-examination-card-by-patient/"
    let urlCreatePatient = API.BE + "/patient/create-new-patient/"
    let urlUpdatePatient = API.BE + "/patient/update-data/"
    
    func getAllPatient() async throws -> [Patient] {
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw NSError(domain: "UserIdNotFound", code: -1, userInfo: [:])
        }
        
        let response: APIResponse<[Patient]> = try await networkService
            .get(urlString: apiGetAllPatient + userId.lowercased(), headers: nil)

        return response.data
    }
    
    func getPatientById(patientId: String) async throws -> Patient {
        let response: APIResponse<Patient> = try await networkService
            .get(urlString: urlGetDataPatient + patientId.lowercased(), headers: nil)

        return response.data
    }
    
    func getAllExamByPatientId(patientId: String) async throws -> [ExaminationResultCardData] {

        let response: APIResponse<[ExaminationResultCardData]> = try await networkService
            .get(urlString: urlGetAllExamByPatientId + patientId, headers: nil)
        
        return response.data
    }
    
    func addNewPatient(patient: Patient) async throws -> Patient {
        guard let adminUserId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw NSError(domain: "UserIdNotFound", code: -1, userInfo: [:])
        }
        
        let response: APIResponse<Patient> = try await networkService.post(
            urlString: urlCreatePatient + adminUserId.lowercased(),
            headers: nil,
            body: patient
        )

        return response.data
    }
    
    func updatePatient(patient: Patient, patientId: String) async throws -> Patient {
        let response: APIResponse<Patient> = try await networkService.update(
            urlString: urlUpdatePatient + patientId.lowercased(),
            headers: nil,
            body: patient
        )

        return response.data
    }
}
