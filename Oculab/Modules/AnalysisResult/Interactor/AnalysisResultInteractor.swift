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
        print(examinationURL + examinationId.lowercased())
        return URL(string: examinationURL + examinationId.lowercased())
    }

    func fetchData(examId: String, completion: @escaping (Result<ExaminationResultData, NetworkErrorType>) -> Void) {
        NetworkHelper.shared
            .get(
                urlString: "https://oculab-be.vercel.app/examination/get-examination-by-id/" +
                    "b12ac121-d42d-4179-864b-154360bce28f"
                    .lowercased())
        { (result: Result<
            APIResponse<Examination>,
            NetworkErrorType
        >) in
            DispatchQueue.main.async {
                switch result {
                case let .success(apiResponse):

                    let examinationDetail = ExaminationResultData(
                        examinationId: apiResponse.data._id.uuidString,
                        imagePreview: apiResponse.data.imagePreview ?? "",
                        fov: apiResponse.data.FOV ?? [],
                        confidenceLevelAggregated: 0.0,
                        systemGrading: GradingType(
                            rawValue: (apiResponse.data.systemResult?.systemGrading)!.rawValue) ??
                            .NEGATIVE,
                        bacteriaTotalCount: apiResponse.data.systemResult?.systemBacteriaTotalCount ?? 0)

                    print("hore")
                    print(examinationDetail)

                    completion(.success(examinationDetail))

                case let .failure(error):
                    completion(.failure(error))
                    print(error)
                }
            }
        }
    }

    func fetchFOVData(examId: String, completion: @escaping (Result<FOVGrouping, NetworkErrorType>) -> Void) {
        NetworkHelper.shared
            .get(
                urlString: "https://oculab-be.vercel.app/fov/get-all-fov-by-examination-id/" +
                    "b12ac121-d42d-4179-864b-154360bce28f"
                    .lowercased())
        { (result: Result<
            APIResponse<FOVGrouping>,
            NetworkErrorType
        >) in
            DispatchQueue.main.async {
                switch result {
                case let .success(apiResponse):

                    print(apiResponse.data)

                    completion(.success(apiResponse.data))

                case let .failure(error):
                    completion(.failure(error))
                    print(error)
                }
            }
        }
    }
}

struct ExaminationResultData: Decodable {
    var examinationId: String
    var imagePreview: String
    var fov: [FOVData]
    var confidenceLevelAggregated: Double
    var systemGrading: GradingType
    var bacteriaTotalCount: Int
}

struct FOVGrouping: Decodable {
    var bta0: [FOVData]
    var bta1to9: [FOVData]
    var btaabove9: [FOVData]

    private enum CodingKeys: String, CodingKey {
        case bta0 = "BTA0"
        case bta1to9 = "BTA1TO9"
        case btaabove9 = "BTAABOVE9"
    }
}
