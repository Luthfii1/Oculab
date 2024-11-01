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

    // nanti ganti Error jadi NetworkErrorType kalo udah pake API
    func getExamById(examId: String, completion: @escaping (Result<ExaminationDetailData, NetworkErrorType>) -> Void) {
        print(urlGetData + examId.lowercased())

        NetworkHelper.shared.get(urlString: urlGetData + examId.lowercased()) { (result: Result<
            APIResponse<Examination>,
            NetworkErrorType
        >) in
            DispatchQueue.main.async {
                switch result {
                case let .success(apiResponse):
                    // Map `ExamResponse` to `ExaminationCardData`
                    let examinationDetail = ExaminationDetailData(
                        pic: apiResponse.data.PIC?.name ?? "Unknown",
                        slideId: apiResponse.data.slideId,
                        examinationGoal: apiResponse.data.goal?.rawValue ?? "No goal specified",
                        type: apiResponse.data.preparationType.rawValue
                    )

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
        examData: ExaminationRequest,
        completion: @escaping (Result<ExaminationResponse, NetworkErrorType>) -> Void
    ) {
        NetworkHelper.shared.post(urlString: urlString, body: examData) { (result: Result<
            APIResponse<ExaminationResponse>,
            NetworkErrorType
        >) in
            DispatchQueue.main.async {
                switch result {
                case let .success(apiResponse):
                    completion(.success(apiResponse.data))
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        }

//        var request = URLRequest(urlString: urlString)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        do {
//            let jsonData = try JSONEncoder().encode(examData)
//            request.httpBody = jsonData
//        } catch {
//            print("Failed to encode examination data: \(error)")
//            return
//        }
//
//        let task = URLSession.shared.dataTask(with: request) { data, _, error in
//            if let error = error {
//                print("Error submitting examination data: \(error)")
//                return
//            }
//            guard let data = data else { return }
//
//            print("Response: \(String(data: data, encoding: .utf8) ?? "")")
//        }
//        task.resume()
    }
}

struct ExaminationRequest: Codable {
    var examination: Examination

    init(examinationId: String, goal: String, preparationType: String, slideId: String, recordVideo: URL?) {
        self.examination = Examination(
            id: examinationId,
            goal: goal,
            preparationType: preparationType,
            slideId: slideId,
            systemBacteriaTotalCount: nil,
            notes: nil,
            recordVideo: recordVideo
        )
    }

    struct Examination: Codable {
        var id: String
        var goal: String
        var preparationType: String
        var slideId: String
        var systemBacteriaTotalCount: Int?
        var notes: String?
        var recordVideo: URL?

        // Map `_id` to `id` to match JSON format
        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case goal, preparationType, slideId, systemBacteriaTotalCount, notes, recordVideo
        }
    }
}

struct ExaminationResponse: Codable {
    var examination: ExaminationData
}

struct ExaminationData: Codable {
    var id: String
    var goal: String
    var preparationType: String
    var slideId: String
    var systemBacteriaTotalCount: Int?
    var notes: String?

    // Map `_id` to `id`
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case goal
        case preparationType
        case slideId
        case systemBacteriaTotalCount
        case notes
    }
}

struct ExaminationDetailData {
    var pic: String
    var slideId: String
    var examinationGoal: String
    var type: String
}

struct PatientDetailData {
    var name: String
    var nik: String
    var dob: String
    var sex: String
    var bpjs: String
}
