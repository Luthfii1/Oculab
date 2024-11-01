//
//  HomeInteractor.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 18/10/24.
//

import Foundation

struct ExaminationStatistic: Decodable {
    var numberOfPositive: Int = 0
    var numberOfNegative: Int = 0
}

// struct ExamResponse: Decodable {
//    var _id: String
//    var goal: String
//    var preparationType: String
//    var slideId: String
//    var examinationDate: String
//    var statusExamination: StatusType
//    var examinationPlanDate: String
// }

class HomeInteractor {
    private let apiURL = API.BE + "/examination/get-number-of-examinations"
    private let apiGetAllData = API.BE + "/examination/get-all-examinations"

    func getStatisticExamination(completion: @escaping (Result<ExaminationStatistic, NetworkErrorType>) -> Void) {
        NetworkHelper.shared.get(urlString: apiURL) { (result: Result<
            APIResponse<ExaminationStatistic>,
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
    }

    func getAllData(completion: @escaping (Result<[ExaminationCardData], NetworkErrorType>) -> Void) {
        NetworkHelper.shared.get(urlString: apiGetAllData) { (result: Result<
            APIResponse<[Examination]>,
            NetworkErrorType
        >) in
            DispatchQueue.main.async {
                switch result {
                case let .success(apiResponse):
                    // Map `ExamResponse` to `ExaminationCardData`
                    let examinationDataCard = apiResponse.data.map { exam -> ExaminationCardData in
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "dd MMMM yyyy"

                        let formattedDate = dateFormatter.string(from: exam.examinationPlanDate ?? Date())
                        return ExaminationCardData(
                            examinationId: exam._id.uuidString,
                            statusExamination: exam.statusExamination,
                            imagePreview: "",
                            datePlan: formattedDate,
                            slideId: exam.slideId,
                            patientName: exam.patientName ?? "",
                            patientDob: exam.patientDoB ?? "",
                            patientId: exam.patientId ?? "")
                    }
                    completion(.success(examinationDataCard))

                case let .failure(error):
                    completion(.failure(error))
                    print(error)
                }
            }
        }
    }
}

//    func getAllData(completion: @escaping (Result<[ExaminationCardData], Error>) -> Void) {
//        // Simulating API data response
//        let jsonData = DummyJSON().examinationCards
//
//        do {
//            let decoder = JSONDecoder()
//            decoder.keyDecodingStrategy = .convertFromSnakeCase
//            decoder.dateDecodingStrategy = .iso8601
//
//            let examinationData = try decoder.decode([Examination].self, from: jsonData)
//
//            let examinationDataCard = examinationData.map { exam -> ExaminationCardData in
//                let dateFormatter = DateFormatter()
//                dateFormatter.dateFormat = "dd MMMM yyyy"
//
//                let timeFormatter = DateFormatter()
//                timeFormatter.dateFormat = "HH:mm"
//
//                let formattedDate = dateFormatter.string(from: exam.examinationDate)
//                let formattedTime = timeFormatter.string(from: exam.examinationDate)
//
//                return ExaminationCardData(
//                    examinationId: exam._id.uuidString,
//                    statusExamination: exam.statusExamination,
//                    imagePreview: exam.imagePreview,
//                    date: formattedDate,
//                    time: formattedTime,
//                    slideId: exam.slideId
//                )
//            }
//            completion(.success(examinationDataCard))
//
//        } catch {
//            DispatchQueue.main.async {
//                completion(.failure(error))
//            }
//            print("Failed to decode data: \(error)")
//        }
//    }
