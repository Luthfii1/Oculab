//
//  HomeInteractor.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 18/10/24.
//

import Foundation

class HomeInteractor {
    private let apiURL = URL(string: "https://example.com/api/examinations")!

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

                let formattedDate = dateFormatter.string(from: exam.timestamp)
                let formattedTime = timeFormatter.string(from: exam.timestamp)

                return ExaminationCardData(
                    examinationId: exam.examinationId.uuidString,
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
