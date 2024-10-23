//
//  AnalysisResultInteractor.swift
//  Oculab
//
//  Created by Risa on 18/10/24.
//

import Foundation

class AnalysisResultInteractor {
//    private /*let examinationURL = "http://localhost:3000/examination/get-examination-by-id/"*/
//    private let fovGroupURL = "http://localhost:3000/fov/create-fov-group/"

    private func createURL(with examinationId: String) -> URL? {
        let examinationURL = "https://oculab-be.vercel.app/examination/get-examination-by-id/"
        return URL(string: examinationURL + examinationId)
    }

    func fetchData(examinationId: String, completion: @escaping (Result<ExaminationResultData, Error>) -> Void) {
        guard let url = createURL(with: examinationId) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0, userInfo: nil)))
                return
            }

            do {
                // Decode only the "data" field
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let dataField = json["data"]
                {
                    // Convert "data" field back to JSON data
                    let dataJson = try JSONSerialization.data(withJSONObject: dataField, options: [])

                    // Decode the JSON data into an ExaminationResultData object
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    decoder.dateDecodingStrategy = .iso8601

                    let examination = try decoder.decode(ExaminationResultData.self, from: dataJson)
                    completion(.success(examination))

                } else {
                    completion(.failure(NSError(domain: "Invalid data format", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

struct ExaminationResultData: Decodable {
    var examinationId: String
    var imagePreview: String
    var fov: [FOV]
    var confidenceLevelAggregated: Double
    var systemGrading: GradingType
    var bacteriaTotalCount: Int
}

struct FOV: Decodable {
    let image: String
    let type: FOVType
    let order: Int
    let fovDataId: String
}

// struct FOVGrouping {
//    var
// }
