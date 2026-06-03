//
//  ExamInteractor.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 18/10/24.
//

import Foundation

class ExamInteractor {
    // MARK: - Dependencies
    private let networkService: NetworkServiceProtocol

    // MARK: - API Endpoints
    private struct APIEndpoints {
        static let createExamination = API.BE + "/examination/create-examination/2t3g4837-13da-4335-97c1-dd5e7eaba549"
        static let getExaminationById = API.BE + "/examination/get-examination-by-id/"
        static let getPatientById = API.BE + "/patient/get-patient-by-id/"
        static let forwardVideoToML = API.BE + "/examination/forward-video-to-ml/"
        static let getAdminExaminationDetail = API.BE + "/examination/get-examination-detail-admin/"
    }
    
    // MARK: - Initialization
    init(networkService: NetworkServiceProtocol = AlamofireNetworkService()) {
        self.networkService = networkService
    }

    // MARK: - Public Methods
    func getExamById(examId: String) async throws -> ExaminationDetailData {
        let response: APIResponse<Examination> = try await networkService
            .get(urlString: APIEndpoints.getExaminationById + examId.lowercased(), headers: nil)

        return ExaminationDetailData(
            examinationId: response.data.id,
            pic: response.data.PIC?.name ?? AppConstants.defaultUnknownValue,
            slideId: response.data.slideId,
            examinationGoal: response.data.goal?.rawValue ?? AppConstants.defaultNoGoalValue,
            type: response.data.preparationType?.rawValue ?? AppConstants.defaultNoTypeValue,
            dpjp: response.data.DPJP?.name ?? AppConstants.defaultUnknownValue
        )
    }

    func getAdminExamDetail(observationId: String) async throws -> AdminExaminationDetailData {
        let response: APIResponse<AdminExaminationDetailData> = try await networkService
            .get(urlString: APIEndpoints.getAdminExaminationDetail + observationId, headers: nil)
        
        return response.data
    }

    func getPatientById(patientId: String) async throws -> PatientDetailData {
        let response: APIResponse<Patient> = try await networkService.get(
            urlString: APIEndpoints.getPatientById + patientId.lowercased(),
            headers: nil
        )

        return PatientDetailData(
            patientId: response.data.id,
            name: response.data.name,
            nik: response.data.NIK,
            dob: response.data.DoB?.formattedDayMonthYear() ?? AppValue.empty,
            sex: response.data.sex.rawValue,
            bpjs: response.data.BPJS ?? AppValue.empty
        )
    }

    func submitExamination(
        examVideo: Data,
        examinationId: String,
        patientId: String
    ) async throws -> APIResponse<ForwardVideoToMLData> {
        let urlString = APIEndpoints.forwardVideoToML + "\(examinationId.lowercased())"
        let parameters = ["video": examVideo]

        return try await networkService.multipart(
            urlString: urlString,
            headers: nil,
            parameters: parameters,
            boundary: nil
        )
    }
}

// MARK: - Data Models
struct ExaminationDetailData {
    let examinationId: String
    let pic: String
    let slideId: String
    let examinationGoal: String
    let type: String
    let dpjp: String
}

struct PatientDetailData {
    let patientId: String
    let name: String
    let nik: String
    let dob: String
    let sex: String
    let bpjs: String
}

struct ForwardVideoToMLData: Decodable {
    let examinationId: String?
    let statusExamination: StatusType?
    let statusML: String?
}
