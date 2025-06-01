//
//  PatientInteractor.swift
//  Oculab
//
//  Created by Risa on 30/05/25.
//

import Foundation

class PatientInteractor: ObservableObject {
    private let apiGetAllPatient = API.BE + "/patient/get-all-patients"
    let urlGetDataPatient = API.BE + "/patient/get-patient-by-id/"
    let urlGetAllExamByPatientId = API.BE + "/examination/get-examination-card-by-patient/"
    let urlCreatePatient = API.BE + "/patient/create-new-patient/"
    
    func getAllPatient() async throws -> [Patient] {
        let response: APIResponse<[Patient]> = try await NetworkHelper.shared.get(urlString: apiGetAllPatient)

        return response.data
    }
    
    func getPatientById(patientId: String) async throws -> Patient {
        let response: APIResponse<Patient> = try await NetworkHelper.shared
            .get(urlString: urlGetDataPatient + patientId.lowercased())

        return response.data
    }
    
    func getAllExamByPatientId(patientId: String) async throws -> [ExaminationResultCardData] {

        let response: APIResponse<[ExaminationResultCardData]> = try await NetworkHelper.shared
            .get(urlString: urlGetAllExamByPatientId + patientId)
        
        return response.data
    }
    
    func addNewPatient(patient: Patient) async throws -> Patient {
        let response: APIResponse<Patient> = try await NetworkHelper.shared.post(
            urlString: urlCreatePatient,
            body: patient
        )

        return response.data
    }
    
//    func getAllExamByPatientId(patientId: String) async throws -> [ExaminationResultCardData] {
//
//        let response: APIResponse<[ExaminationResultCardData]> = try await NetworkHelper.shared
//            .get(urlString: urlGetAllExamByPatientId + patientId)
//        
//        return response.data
//    }
}
