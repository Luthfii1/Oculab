//
//  ExamInteractor.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 18/10/24.
//

import Foundation

class ExamInteractor {
    let urlString = API.BE_Prod + "/examination/create-examination/2t3g4837-13da-4335-97c1-dd5e7eaba549"

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
