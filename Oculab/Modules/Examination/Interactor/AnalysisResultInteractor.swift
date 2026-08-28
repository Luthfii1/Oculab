//
//  AnalysisResultInteractor.swift
//  Oculab
//
//  Created by Risa on 18/10/24.
//

import Foundation

class AnalysisResultInteractor {
    // MARK: - Dependencies
    private let networkService: NetworkServiceProtocol
    
    // MARK: - API Endpoints
    private struct APIEndpoints {
        static let examination = API.BE + "/examination/get-examination-by-id/"
        static let expertResult = API.BE + "/expertResult/post-expert-result/"
        static let trackingDuration = API.BE + "/tracking/post-tracking-duration/"
    }

    // MARK: - Initialization
    init(networkService: NetworkServiceProtocol = DependencyInjection.shared.networkService) {
        self.networkService = networkService
    }
    
    // MARK: - Private Methods
    private func createURL(with examinationId: String) -> URL? {
        let urlString = APIEndpoints.examination + examinationId.lowercased()
        Logger.debug("Creating URL: \(urlString)", category: .examination)
        return URL(string: urlString)
    }

    // MARK: - Public Methods
    func submitExpertResult(examId: String, expertResult: ExpertExamResult) async throws -> ExpertExamResult {
        let response: APIResponse<ExpertExamResult> = try await networkService.post(
            urlString: APIEndpoints.expertResult + examId,
            headers: nil,
            body: expertResult
        )

        return response.data
    }

    func fetchData(examId: String) async throws -> ExaminationResultData {
        let response: APIResponse<Examination> = try await networkService
            .get(urlString: API.BE + "/examination/get-examination-by-id/" + examId.lowercased(), headers: nil)

        let examinationDetail = ExaminationResultData(
            examinationId: response.data.id,
            slideId: response.data.slideId,
            imagePreview: response.data.imagePreview ?? AppValue.empty,

            fov: response.data.FOV ?? [],
            confidenceLevelAggregated: response.data.systemResult?.confidenceLevelAggregated ?? 0,
            systemGrading: response.data.systemResult?.systemGrading ?? .unknown,
            expertGrading: response.data.expertResult?.finalGrading,
            bacteriaTotalCount: response.data.systemResult?.systemBacteriaTotalCount ?? 0,
            expertNote: {
                let notes = response.data.expertResult?.notes ?? AppValue.empty
                return notes.isEmpty ? "examination.interpretation.no_staff_notes".localized : notes
            }(),
            statusExamination: response.data.statusExamination,
            patientId: response.data.patientId)

        return examinationDetail
    }

    func fetchFOVData(examId: String) async throws -> FOVGrouping {
        let response: APIResponse<FOVGrouping> = try await networkService.get(
            urlString: API.BE + "/fov/get-all-fov-by-examination-id/" + examId.lowercased(), 
            headers: nil
        )
        return response.data
    }

    func verifyingFOV(fovId: String) async throws -> FOVData {
        let response: APIResponse<FOVData> = try await networkService.update(
            urlString: API.BE + "/fov/update-verified-field/" + fovId.lowercased(),
            headers: nil,
            body: EmptyBody()
        )
        return response.data
    }

    func submitTrackingDuration(examId: String, body: TrackingDurationRequest) async throws -> TrackingDurationRequest {
        Logger.info("Submitting tracking duration for exam: \(examId)", category: .examination)
        
        let response: APIResponse<TrackingDurationRequest> = try await networkService.post(
            urlString: API.BE + "/examinationAnalysisDuration/create-analysis-duration/" + examId,
            headers: nil,
            body: body
        )

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
    var patientId: String?
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
