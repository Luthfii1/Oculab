//
//  ExamInteractor.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 18/10/24.
//

import Foundation

class ExamInteractor {
    let urlString = API.BE + "/examination/create-examination/2t3g4837-13da-4335-97c1-dd5e7eaba549"
    let urlGetData = API.BE + "/examination/get-examination-by-id/"
    let urlGetDataPatient = API.BE + "/patient/get-patient-by-id/"
    let urlForwardVideo = API.BE + "/examination/forward-video-to-ml/"

    func getExamById(examId: String) async throws -> ExaminationDetailData {
        let response: APIResponse<Examination> = try await NetworkHelper.shared
            .get(urlString: urlGetData + examId.lowercased())

        let examinationDetail = ExaminationDetailData(
            examinationId: response.data._id,
            pic: response.data.PIC?.name ?? "Unknown",
            slideId: response.data.slideId,
            examinationGoal: response.data.goal?.rawValue ?? "No goal specified",
            type: response.data.preparationType?.rawValue ?? "No type specified",
            dpjp: response.data.DPJP?.name ?? "Unknown"
        )

        return examinationDetail
    }

    func getPatientById(
        patientId: String
    ) async throws -> PatientDetailData {
        let response: APIResponse<Patient> = try await NetworkHelper.shared.get(
            urlString: urlGetDataPatient + patientId.lowercased()
        )

        return PatientDetailData(
            patientId: response.data._id,
            name: response.data.name,
            nik: response.data.NIK,
            dob: response.data.DoB?.formattedString() ?? "",
            sex: response.data.sex.rawValue,
            bpjs: response.data.BPJS ?? ""
        )
    }

    func submitExamination(
        examVideo: Data,
        examinationId: String,
        patientId: String
    ) async throws -> APIResponse<Response> {
        let urlString = urlForwardVideo + "\(examinationId.lowercased())"
        let parameters = ["video": examVideo]

        return try await NetworkHelper.shared.multipart(
            urlString: urlString,
            parameters: parameters
        )
    }
}

struct ExaminationDetailData {
    var examinationId: String
    var pic: String
    var slideId: String
    var examinationGoal: String
    var type: String
    var dpjp: String
}

struct PatientDetailData {
    var patientId: String
    var name: String
    var nik: String
    var dob: String
    var sex: String
    var bpjs: String
}

struct Response: Decodable {
    var statusML: String
}
