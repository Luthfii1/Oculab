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
        let jsonData = """
        [
            {
                "examinationId": "sampleId1",
                "statusExamination": "completed",
                "imagePreview": "https://is3.cloudhost.id/oculab-fov/oculab-fov/eead8004-2fd7-4f40-be1f-1d02cb886af4.png",
                "timestamp": "2022-01-01T12:00:00Z",
                "slideId": "slide1"
            },
            {
                "examinationId": "sampleId2",
                "statusExamination": "completed",
                "imagePreview": "https://is3.cloudhost.id/oculab-fov/oculab-fov/eead8004-2fd7-4f40-be1f-1d02cb886af4.png",
                "timestamp": "2022-01-02T12:00:00Z",
                "slideId": "slide2"
            },
            {
                "examinationId": "sampleId3",
                "statusExamination": "completed",
                "imagePreview": "https://is3.cloudhost.id/oculab-fov/oculab-fov/eead8004-2fd7-4f40-be1f-1d02cb886af4.png",
                "timestamp": "2022-01-12T12:00:00Z",
                "slideId": "slide3"
            },
            {
                "examinationId": "sampleId4",
                "statusExamination": "pending",
                "imagePreview": "https://is3.cloudhost.id/oculab-fov/oculab-fov/eead8004-2fd7-4f40-be1f-1d02cb886af4.png",
                "timestamp": "2022-01-12T12:00:00Z",
                "slideId": "slide4"
            },
            {
                "examinationId": "sampleId5",
                "statusExamination": "pending",
                "imagePreview": "https://is3.cloudhost.id/oculab-fov/oculab-fov/eead8004-2fd7-4f40-be1f-1d02cb886af4.png",
                "timestamp": "2022-01-12T12:00:00Z",
                "slideId": "slide5"
            },
        ]
        """.data(using: .utf8)!

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

struct ExaminationCardData: Decodable, Identifiable {
    var id: String {
        examinationId
    }

    var examinationId: String
    var statusExamination: StatusType
    var imagePreview: String
    var date: String
    var time: String
    var slideId: String
}
