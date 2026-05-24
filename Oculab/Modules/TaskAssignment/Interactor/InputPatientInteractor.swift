//
//  InputPatientInteractor.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 07/11/24.
//

import Foundation

class InputPatientInteractor {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = AlamofireNetworkService()) {
        self.networkService = networkService
    }
    
    private let apiGetAllUser = API.BE + "/user/get-all-pics/"
    private let apiGetAllPatient = API.BE + "/patient/get-all-patients/"
    let urlGetDataPatient = API.BE + "/patient/get-patient-by-id/"
    let urlGetDataUser = API.BE + "/user/get-user-data-by-id/"
    let urlCreatePatient = API.BE + "/patient/create-new-patient/"
    let urlCreateExam = API.BE + "/examination/create-examination/"

    func getAllUser() async throws -> [User] {
        guard let adminUserId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw NSError(
                domain: "UserIdNotFound",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "User ID not found"]
            )
        }
        
        guard let token = KeychainHelper.string(for: .accessToken) else {
            throw URLError(.userAuthenticationRequired)
        }

        let headers = [
            "Authorization": "Bearer \(token)"
        ]
        
        let response: APIResponse<[User]> = try await networkService
            .get(urlString: apiGetAllUser + adminUserId.lowercased(),
                 headers: headers)

        return response.data
    }

    func getAllPatient() async throws -> [Patient] {
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw NSError(domain: "UserIdNotFound", code: -1, userInfo: [:])
        }
        
        let response: APIResponse<[Patient]> = try await networkService
            .get(urlString: apiGetAllPatient + userId.lowercased(), headers: nil)

        return response.data
    }

    func getPatientById(
        patientId: String
    ) async throws -> Patient {
        let response: APIResponse<Patient> = try await networkService
            .get(urlString: urlGetDataPatient + patientId.lowercased(), headers: nil)

        return response.data
    }

    func getUserById(
        userId: String
    ) async throws -> User {
        let response: APIResponse<User> = try await networkService
            .get(urlString: urlGetDataUser + userId.lowercased(), headers: nil)

        return response.data
    }

    func addNewPatient(
        patient: Patient
    ) async throws -> Patient {
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

    func addNewExamination(
        patientId: String,
        examinations: [ExaminationRequest]
    ) async throws -> ExaminationDataResponse {
        let response: APIResponse<ExaminationDataResponse> = try await networkService.post(
            urlString: urlCreateExam + patientId,
            headers: nil,
            body: examinations
        )
        
        let createdExams = response.data.examinations
        Logger.info("Successfully created \(createdExams.count) examination(s)", category: .taskAssignment)
        for exam in createdExams {
            Logger.debug("Created exam - ID: \(exam._id), Slide: \(exam.slideId), Type: \(exam.preparationType)", category: .taskAssignment)
        }
        
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

enum ExaminationDataResponse: Decodable {
    case single(AddExaminationResponse)
    case multiple([AddExaminationResponse])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let multipleExams = try? container.decode([AddExaminationResponse].self) {
            self = .multiple(multipleExams)
        } else if let singleExam = try? container.decode(AddExaminationResponse.self) {
            self = .single(singleExam)
        } else {
            throw DecodingError.typeMismatch(ExaminationDataResponse.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                debugDescription: "Expected single examination or array of examinations"))
        }
    }
    
    var examinations: [AddExaminationResponse] {
        switch self {
        case .single(let exam):
            return [exam]
        case .multiple(let exams):
            return exams
        }
    }
}
