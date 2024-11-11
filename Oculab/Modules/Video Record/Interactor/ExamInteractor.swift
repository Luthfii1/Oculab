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
//    let urlForwardVideo = "https://f097-158-140-189-122.ngrok-free.app" + "/examination/forward-video-to-ml/"

    func getExamById(examId: String, completion: @escaping (Result<ExaminationDetailData, ApiErrorData>) -> Void) {
        print(urlGetData + examId.lowercased())

        NetworkHelper.shared.get(urlString: urlGetData + examId.lowercased()) { (result: Result<
            APIResponse<Examination>,
            APIResponse<ApiErrorData>
        >) in
            DispatchQueue.main.async {
                switch result {
                case let .success(successResponse):
                    let examinationDetail = ExaminationDetailData(
                        examinationId: successResponse.data._id.uuidString,
                        pic: successResponse.data.PIC?.name ?? "Unknown",
                        slideId: successResponse.data.slideId,
                        examinationGoal: successResponse.data.goal?.rawValue ?? "No goal specified",
                        type: successResponse.data.preparationType.rawValue
                    )

                    completion(.success(examinationDetail))

                case let .failure(error):
                    completion(.failure(error.data))
                }
            }
        }
    }

    func getPatientById(
        patientId: String,
        completion: @escaping (Result<PatientDetailData, ApiErrorData>) -> Void
    ) {
        NetworkHelper.shared.get(urlString: urlGetDataPatient + patientId.lowercased()) { (result: Result<
            APIResponse<Patient>,
            APIResponse<ApiErrorData>
        >) in
            DispatchQueue.main.async {
                switch result {
                case let .success(successResponse):
                    let patientDetail = PatientDetailData(
                        patientId: successResponse.data._id.uuidString,
                        name: successResponse.data.name,
                        nik: successResponse.data.NIK,
                        dob: successResponse.data.DoB?.formattedString() ?? "",
                        sex: successResponse.data.sex.rawValue,
                        bpjs: successResponse.data.BPJS ?? ""
                    )

                    completion(.success(patientDetail))

                case let .failure(error):
                    completion(.failure(error.data))
                }
            }
        }
    }

    func submitExamination(
        examVideo: Data,
        examinationId: String,
        patientId: String,
        completion: @escaping (Result<APIResponse<Response>, APIResponse<ApiErrorData>>) -> Void
    ) {
        let urlString = urlForwardVideo + patientId.lowercased() + "/\(examinationId.lowercased())"
        print(urlString)
        let boundary = UUID().uuidString

        // Prepare parameters for multipart request
        let parameters = ["video": examVideo]

        // Create the multipart request
        guard let request = NetworkHelper.shared.createMultipartRequest(
            urlString: urlString,
            httpMethod: "POST",
            parameters: parameters,
            boundary: boundary
        ) else {
            completion(.failure(NetworkHelper.shared.createErrorSystem(
                errorType: "ERROR_CREATE_MULTIPART_REQUEST",
                errorMessage: "error create multipart request"
            )))
            return
        }

        // Execute the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            NetworkHelper.shared.handleResponse(data, response, error, completion: completion)
        }.resume()
    }
}

struct ExaminationDetailData {
    var examinationId: String
    var pic: String
    var slideId: String
    var examinationGoal: String
    var type: String
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
    var message: String?
    var data: String?
    var error: String?
}

struct ForwardBody: Encodable {
    var video: Data
}
