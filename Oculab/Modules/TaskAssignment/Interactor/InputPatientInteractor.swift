//
//  InputPatientInteractor.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 07/11/24.
//

import Foundation

class InputPatientInteractor {
    private let apiGetAllUser = API.BE + "/user/get-all-pics"
    private let apiGetAllPatient = API.BE + "/patient/get-all-patients"
    let urlGetDataPatient = API.BE + "/patient/get-patient-by-id/"
    let urlGetDataUser = API.BE + "/user/get-user-data-by-id/"
    let urlCreatePatient = API.BE + "/patient/create-new-patient/"
    let urlCreateExam = API.BE + "/examination/create-examination/"

    func getAllUser() async throws -> [User] {
        let response: APIResponse<[User]> = try await NetworkHelper.shared.get(urlString: apiGetAllUser)

        return response.data
    }

    func getAllPatient() async throws -> [Patient] {
        let response: APIResponse<[Patient]> = try await NetworkHelper.shared.get(urlString: apiGetAllPatient)

        return response.data
    }

    func getPatientById(
        patientId: String
    ) async throws -> Patient {
        let response: APIResponse<Patient> = try await NetworkHelper.shared
            .get(urlString: urlGetDataPatient + patientId.lowercased())

        return response.data
    }

    func getUserById(
        userId: String
    ) async throws -> User {
        let response: APIResponse<User> = try await NetworkHelper.shared
            .get(urlString: urlGetDataUser + userId.lowercased())

        return response.data
    }

    func addNewPatient(
        patient: Patient
    ) async throws -> Patient {
        let response: APIResponse<Patient> = try await NetworkHelper.shared.post(
            urlString: urlCreatePatient,
            body: patient
        )

        return response.data
    }

    func addNewExamination(
        patientId: String,
        examination: ExaminationRequest
    ) async throws -> AddExaminationResponse {
        let response: APIResponse<AddExaminationResponse> = try await NetworkHelper.shared.post(
            urlString: urlCreateExam + patientId,
            body: examination
        )
        print("response: \(response.code)")
        print("response: \(response.status)")
        print("response: \(response.message)")

        return response.data
    }
}

struct ErrorMessage: Decodable {
    var errorType: String
    var description: String
}

struct AddExaminationResponse: Decodable {
    var _id: String
    var goal: ExamGoalType
    var preparationType: ExamPreparationType
    var slideId: String
    var examinationDate: String
    var statusExamination: StatusType
    var PIC: String
    var examinationPlanDate: String
    var DPJP: String
}
