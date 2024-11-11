//
//  AnalysisResultInteractor.swift
//  Oculab
//
//  Created by Risa on 18/10/24.
//

import Foundation

class AnalysisResultInteractor {
    private func createURL(with examinationId: String) -> URL? {
        let examinationURL = "https://oculab-be.vercel.app/examination/get-examination-by-id/"
        print(examinationURL + examinationId.lowercased())
        return URL(string: examinationURL + examinationId.lowercased())
    }

    func fetchData(examId: String, completion: @escaping (Result<ExaminationResultData, ApiErrorData>) -> Void) {
        NetworkHelper.shared
            .get(
                urlString: "https://oculab-be.vercel.app/examination/get-examination-by-id/" + examId.lowercased())
        { (result: Result<
            APIResponse<Examination>,
            APIResponse<ApiErrorData>
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
                            rawValue: apiResponse.data.systemResult?.systemGrading.rawValue ?? GradingType.NEGATIVE
                                .rawValue) ??
                            .unknown,
                        bacteriaTotalCount: apiResponse.data.systemResult?.systemBacteriaTotalCount ?? 0)

                    completion(.success(examinationDetail))
                case let .failure(error):
                    completion(.failure(error.data))
                }
            }
        }
    }

    func fetchFOVData(examId: String, completion: @escaping (Result<FOVGrouping, ApiErrorData>) -> Void) {
        print(
            "https://oculab-be.vercel.app/fov/get-all-fov-by-examination-id/" +
                examId.lowercased())
        NetworkHelper.shared
            .get(
                urlString: "https://oculab-be.vercel.app/fov/get-all-fov-by-examination-id/" +
                    examId.lowercased())
        { (result: Result<
            APIResponse<FOVGrouping>,
            APIResponse<ApiErrorData>
        >) in
            DispatchQueue.main.async {
                switch result {
                case let .success(apiResponse):
                    completion(.success(apiResponse.data))

                case let .failure(error):
                    completion(.failure(error.data))
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
    var bta0: [FOVData] = []
    var bta1to9: [FOVData] = []
    var btaabove9: [FOVData] = []

    private enum CodingKeys: String, CodingKey {
        case bta0 = "BTA0"
        case bta1to9 = "BTA1TO9"
        case btaabove9 = "BTAABOVE9"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.bta0 = try container.decodeIfPresent([FOVData].self, forKey: .bta0) ?? []
        self.bta1to9 = try container.decodeIfPresent([FOVData].self, forKey: .bta1to9) ?? []
        self.btaabove9 = try container.decodeIfPresent([FOVData].self, forKey: .btaabove9) ?? []
    }
}
