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

class HomeInteractor {
    private let apiURL = API.BE + "/examination/get-number-of-examinations"

    func getStatisticExamination(completion: @escaping (Result<ExaminationStatistic, NetworkErrorType>) -> Void) {
        NetworkHelper.shared.get(urlString: apiURL) { (result: Result<
            APIResponse<ExaminationStatistic>,
            NetworkErrorType
        >) in
            DispatchQueue.main.async {
                switch result {
                case let .success(apiResponse):
                    // Use apiResponse.data to access the ExaminationStatistic
                    completion(.success(apiResponse.data))
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        }
    }

    func getAllData(completion: @escaping (Result<[ExaminationCardData], Error>) -> Void) {
        // Simulating API data response
        let jsonData = DummyJSON().examinationCards

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601

            let examinationData = try decoder.decode([Examination].self, from: jsonData)

            let examinationDataCard = examinationData.map { exam -> ExaminationCardData in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd MMMM yyyy"

                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"

                let formattedDate = dateFormatter.string(from: exam.examinationDate)
                let formattedTime = timeFormatter.string(from: exam.examinationDate)

                return ExaminationCardData(
                    examinationId: exam._id.uuidString,
                    statusExamination: exam.statusExamination,
                    imagePreview: exam.imagePreview,
                    date: formattedDate,
                    time: formattedTime,
                    slideId: exam.slideId
                )
            }
            completion(.success(examinationDataCard))

        } catch {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            print("Failed to decode data: \(error)")
        }
    }
}
