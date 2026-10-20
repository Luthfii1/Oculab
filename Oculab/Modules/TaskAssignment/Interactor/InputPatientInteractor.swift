//
//  InputPatientInteractor.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 07/11/24.
//

import Foundation

class InputPatientInteractor {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = DependencyInjection.shared.networkService) {
        self.networkService = networkService
    }
    
    private let apiGetAllUser = API.BE + "/user/get-all-pics/"
    private let apiGetAllPatient = API.BE + "/patient/get-all-patients/"
    let urlGetDataPatient = API.BE + "/patient/get-patient-by-id/"
    let urlGetDataUser = API.BE + "/user/get-user-data-by-id/"
    let urlCreatePatient = API.BE + "/patient/create-new-patient/"
    let urlCreateExam = API.BE + "/examination/create-examination/"

    @MainActor
    func getAllUser() async throws -> [User] {
        let session = try sessionSnapshot()
        let headers = try AuthSessionManager.authorizationHeaders()
        let response: APIResponse<[User]> = try await ClinicalRequestContext.withSession(session) {
            try await networkService.get(
                urlString: apiGetAllUser + session.ownerUserId, headers: headers)
        }

        try requireCurrentSession(session)
        return response.data
    }

    @MainActor
    func getAllPatient() async throws -> [Patient] {
        let session = try sessionSnapshot()
        let headers = try AuthSessionManager.authorizationHeaders()
        let response: APIResponse<[Patient]> = try await ClinicalRequestContext.withSession(session) {
            try await networkService.get(
                urlString: apiGetAllPatient + session.ownerUserId, headers: headers)
        }

        try requireCurrentSession(session)
        return response.data
    }

    @MainActor
    func getPatientById(patientId: String) async throws -> Patient {
        let session = try sessionSnapshot()
        let headers = try AuthSessionManager.authorizationHeaders()
        let requestedID = patientId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !requestedID.isEmpty else { throw URLError(.badURL) }
        let response: APIResponse<Patient> = try await ClinicalRequestContext.withSession(session) {
            try await networkService.get(
                urlString: urlGetDataPatient + requestedID, headers: headers)
        }

        try requireCurrentSession(session)
        guard response.data.id.lowercased() == requestedID else { throw URLError(.cannotParseResponse) }
        return response.data
    }

    @MainActor
    func getUserById(userId: String) async throws -> User {
        let session = try sessionSnapshot()
        let headers = try AuthSessionManager.authorizationHeaders()
        let requestedID = userId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !requestedID.isEmpty else { throw URLError(.badURL) }
        let response: APIResponse<User> = try await ClinicalRequestContext.withSession(session) {
            try await networkService.get(
                urlString: urlGetDataUser + requestedID, headers: headers)
        }

        try requireCurrentSession(session)
        guard response.data.id.lowercased() == requestedID else { throw URLError(.cannotParseResponse) }
        return response.data
    }

    @MainActor
    func addNewPatient(patient: Patient) async throws -> Patient {
        let session = try sessionSnapshot()
        let headers = try AuthSessionManager.authorizationHeaders()
        let response: APIResponse<Patient> = try await ClinicalRequestContext.withSession(session) {
            try await networkService.post(
                urlString: urlCreatePatient + session.ownerUserId, headers: headers, body: patient)
        }

        try requireCurrentSession(session)
        guard !response.data.id.isEmpty else { throw URLError(.cannotParseResponse) }
        return response.data
    }

    @MainActor
    func addNewExamination(patientId: String, examinations: [ExaminationRequest]) async throws -> ExaminationDataResponse {
        let session = try sessionSnapshot()
        let headers = try AuthSessionManager.authorizationHeaders()
        let requestedID = patientId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !requestedID.isEmpty else { throw URLError(.badURL) }
        let response: APIResponse<ExaminationDataResponse> = try await ClinicalRequestContext.withSession(session) {
            try await networkService.post(
                urlString: urlCreateExam + requestedID, headers: headers, body: examinations)
        }

        try requireCurrentSession(session)
        Logger.info("Successfully created examination task(s)", category: .taskAssignment)
        return response.data
    }

    @MainActor
    private func sessionSnapshot() throws -> UploadQueueSession {
        try Task.checkCancellation()
        guard let session = AuthSessionManager.uploadQueueSession else { throw URLError(.userAuthenticationRequired) }
        return session
    }

    @MainActor
    private func requireCurrentSession(_ expected: UploadQueueSession) throws {
        try Task.checkCancellation()
        guard expected == AuthSessionManager.uploadQueueSession else { throw CancellationError() }
    }
}

struct ErrorMessage: Decodable {
    var errorType: String
    var description: String
}

struct AddExaminationResponse: Decodable {
    var id: String
    var goal: ExamGoalType
    var preparationType: ExamPreparationType
    var slideId: String
    var examinationDate: String
    var statusExamination: StatusType
    var PIC: String
    var examinationPlanDate: String
    var DPJP: String

    enum CodingKeys: String, CodingKey {
        case id
        case legacyId = "_id"
        case goal
        case preparationType
        case slideId
        case examinationDate
        case statusExamination
        case PIC
        case picId
        case examinationPlanDate
        case DPJP
        case dpjpId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decodedId = try container.decodeIfPresent(String.self, forKey: .id) {
            id = decodedId
        } else if let legacyId = try container.decodeIfPresent(String.self, forKey: .legacyId) {
            id = legacyId
        } else {
            id = AppValue.empty
        }
        goal = try container.decode(ExamGoalType.self, forKey: .goal)
        preparationType = try container.decode(ExamPreparationType.self, forKey: .preparationType)
        slideId = try container.decode(String.self, forKey: .slideId)
        examinationDate = try container.decodeIfPresent(String.self, forKey: .examinationDate) ?? AppValue.empty
        statusExamination = try container.decode(StatusType.self, forKey: .statusExamination)
        PIC = Self.decodeString(
            from: container,
            keys: [.PIC, .picId]
        )
        examinationPlanDate = try container.decodeIfPresent(String.self, forKey: .examinationPlanDate) ?? AppValue.empty
        DPJP = Self.decodeString(
            from: container,
            keys: [.DPJP, .dpjpId]
        )
    }

    private static func decodeString(
        from container: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys]
    ) -> String {
        for key in keys {
            if let value = try? container.decode(String.self, forKey: key),
               !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
        }
        return AppValue.empty
    }
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
