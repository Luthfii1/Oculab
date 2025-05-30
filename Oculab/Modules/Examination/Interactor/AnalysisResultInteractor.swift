//
//  AnalysisResultInteractor.swift
//  Oculab
//
//  Created by Risa on 18/10/24.
//

import Foundation

class AnalysisResultInteractor {
    private func createURL(with examinationId: String) -> URL? {
        let examinationURL = API.BE + "/examination/get-examination-by-id/"
        print(examinationURL + examinationId.lowercased())
        return URL(string: examinationURL + examinationId.lowercased())
    }

    func submitExpertResult(examId: String, expertResult: ExpertExamResult) async throws -> ExpertExamResult {
        let response: APIResponse<ExpertExamResult> = try await NetworkHelper.shared.post(
            urlString: API.BE + "/expertResult/post-expert-result/" + examId,
            body: expertResult)

        return response.data
    }

    func fetchData(examId: String) async throws -> ExaminationResultData {
        let response: APIResponse<Examination> = try await NetworkHelper.shared
            .get(urlString: API.BE + "/examination/get-examination-by-id/" + examId.lowercased())

        let examinationDetail = ExaminationResultData(
            examinationId: response.data._id,
            slideId: response.data.slideId,
            imagePreview: response.data.imagePreview ?? "",

            fov: response.data.FOV ?? [],
            confidenceLevelAggregated: response.data.systemResult?.confidenceLevelAggregated ?? 0,
            systemGrading: GradingType(
                rawValue: response.data.systemResult?.systemGrading.rawValue ?? GradingType.NEGATIVE
                    .rawValue) ??
                .unknown,
            expertGrading: GradingType(
                rawValue: response.data.expertResult?.finalGrading.rawValue ?? GradingType.NEGATIVE
                    .rawValue) ?? .unknown,
            bacteriaTotalCount: response.data.systemResult?.systemBacteriaTotalCount ?? 0,
            expertNote: response.data.expertResult?.notes ?? "")

        return examinationDetail
    }

    func fetchFOVData(examId: String) async throws -> FOVGrouping {
        let response: APIResponse<FOVGrouping> = try await NetworkHelper.shared.get(
            urlString: API.BE + "/fov/get-all-fov-by-examination-id/" +
                examId.lowercased())
        return response.data
    }
}

struct ExaminationResultData: Decodable {
    var examinationId: String
    var slideId: String
    var imagePreview: String
    var fov: [FOVData]
    var confidenceLevelAggregated: Double
    var systemGrading: GradingType
    var expertGrading: GradingType?
    var bacteriaTotalCount: Int
    var expertNote: String?
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
