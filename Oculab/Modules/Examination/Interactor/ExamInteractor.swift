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

    func getExamById(examId: String, completion: @escaping (Result<ExaminationDetailData, NetworkErrorType>) -> Void) {
        print(urlGetData + examId.lowercased())

        NetworkHelper.shared.get(urlString: urlGetData + examId.lowercased()) { (result: Result<
            APIResponse<Examination>,
            NetworkErrorType
        >) in
            DispatchQueue.main.async {
                switch result {
                case let .success(apiResponse):
                    let examinationDetail = ExaminationDetailData(
                        examinationId: apiResponse.data._id,
                        pic: apiResponse.data.PIC?.name ?? "Unknown",
                        slideId: apiResponse.data.slideId,
                        examinationGoal: apiResponse.data.goal?.rawValue ?? "No goal specified",
                        type: apiResponse.data.preparationType.rawValue,
                        dpjp: apiResponse.data.DPJP?.name ?? "Unknown"
                    )

                    print(examinationDetail)

                    completion(.success(examinationDetail))

                case let .failure(error):
                    completion(.failure(error))
                    print(error)
                }
            }
        }
    }

    func getPatientById(
        patientId: String,
        completion: @escaping (Result<PatientDetailData, NetworkErrorType>) -> Void
    ) {
        print(urlGetDataPatient + patientId.lowercased())

        NetworkHelper.shared.get(urlString: urlGetDataPatient + patientId.lowercased()) { (result: Result<
            APIResponse<Patient>,
            NetworkErrorType
        >) in
            DispatchQueue.main.async {
                switch result {
                case let .success(apiResponse):
                    let patientDetail = PatientDetailData(
                        patientId: apiResponse.data._id.uuidString,
                        name: apiResponse.data.name,
                        nik: apiResponse.data.NIK,
                        dob: apiResponse.data.DoB?.formattedString() ?? "",
                        sex: apiResponse.data.sex.rawValue,
                        bpjs: apiResponse.data.BPJS ?? ""
                    )

                    completion(.success(patientDetail))

                case let .failure(error):
                    completion(.failure(error))
                    print(error)
                }
            }
        }
    }

    func submitExamination(
        examVideo: Data,
        examinationId: String,
        patientId: String,
        completion: @escaping (Result<Response, NetworkErrorType>) -> Void
    ) {
        let urlString = urlForwardVideo + patientId.lowercased() + "/\(examinationId.lowercased())"
        print(urlString)
        let boundary = UUID().uuidString

        let parameters = ["video": examVideo]

        guard let request = NetworkHelper.shared.createMultipartRequest(
            urlString: urlString,
            httpMethod: "POST",
            parameters: parameters,
            boundary: boundary
        ) else {
            completion(.failure(.invalidURL))
            return
        }

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
    var message: String?
    var data: String?
    var error: String?
}
