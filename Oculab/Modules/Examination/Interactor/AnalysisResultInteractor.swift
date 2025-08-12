//
//  AnalysisResultInteractor.swift
//  Oculab
//
//  Created by Risa on 18/10/24.
//

import Foundation

class AnalysisResultInteractor {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = AlamofireNetworkService()) {
        self.networkService = networkService
    }
    
    private func createURL(with examinationId: String) -> URL? {
        let examinationURL = API.BE + "/examination/get-examination-by-id/"
        print(examinationURL + examinationId.lowercased())
        return URL(string: examinationURL + examinationId.lowercased())
    }

    func submitExpertResult(examId: String, expertResult: ExpertExamResult) async throws -> ExpertExamResult {
        let response: APIResponse<ExpertExamResult> = try await networkService.post(
            urlString: API.BE + "/expertResult/post-expert-result/" + examId,
            headers: nil,
            body: expertResult)

        return response.data
    }

    func fetchData(examId: String) async throws -> ExaminationResultData {
        let response: APIResponse<Examination> = try await networkService
            .get(urlString: API.BE + "/examination/get-examination-by-id/" + examId.lowercased(), headers: nil)

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
            expertNote: response.data.expertResult?.notes ?? "",
            statusExamination: response.data.statusExamination)

        return examinationDetail
    }

    func fetchFOVData(examId: String) async throws -> FOVGrouping {
        let response: APIResponse<FOVGrouping> = try await networkService.get(
            urlString: API.BE + "/fov/get-all-fov-by-examination-id/" +
                examId.lowercased(), headers: nil)
        return response.data
    }

    func submitTrackingDuration(examId: String, body: TrackingDurationRequest) async throws -> TrackingDurationRequest {
        print(examId)
        let response: APIResponse<TrackingDurationRequest> = try await networkService.post(
            urlString: API.BE + "/examinationAnalysisDuration/create-analysis-duration/" + examId,
            headers: nil,
            body: body)

        return response.data
    }
}

struct TrackingDurationRequest: Encodable, Decodable {
    var examinationId: String?
    var analysisSourceType = "MOBILE"
    var startTimestamp: String
    var endTimestamp: String
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
    var statusExamination: StatusType
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
