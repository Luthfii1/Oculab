//
//  HomeInteractor.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 18/10/24.
//

import Foundation

struct ExaminationStatistic: Decodable {
    var negatifCount: Int
    var positifCount: Int
}

class HomeInteractor {
    private let apiURL = "https://jsonplaceholder.typicode.com/todos/1"

    func getStatisticExamination(completion: @escaping (Result<Todo, NetworkErrorType>) -> Void) {
        NetworkHelper.shared.get(urlString: apiURL) { (result: Result<Todo, NetworkErrorType>) in
            DispatchQueue.main.async {
//                    print("res: ", result)
                completion(result) // Forward result to presenter
            }
        }
    }

//    func exampleNetworkManager() {
//        let updateData = UpdateExaminationData(examinationId: "sampleId", statusExamination: "completed")
//        NetworkHelper.shared.update(urlString: "https://example.com/api/examinations/\(updateData.examinationId)", body: updateData) { (result: Result<ExaminationDataResponse, NetworkErrorType>) in
//            switch result {
//            case .success(let data):
//                print("Data updated successfully: \(data)")
//            case .failure(let error):
//                print("Error occurred: \(error)")
//            }
//        }
//    }

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
