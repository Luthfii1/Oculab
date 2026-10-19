//
//  ExamInteractor.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 18/10/24.
//

import Foundation

class ExamInteractor {
    // MARK: - Dependencies
    private let networkService: NetworkServiceProtocol

    // MARK: - API Endpoints
    private struct APIEndpoints {
        static let getExaminationById = API.BE + "/examination/get-examination-by-id/"
        static let getPatientById = API.BE + "/patient/get-patient-by-id/"
        static let forwardVideoToML = API.BE + "/examination/forward-video-to-ml/"
        static let analysisSubmissions = API.BE + "/examination/analysis-submissions/"
        static let getAdminExaminationDetail = API.BE + "/examination/get-examination-detail-admin/"
        static let adminUpdateObservation = API.BE + "/examination/observation/"
        static let facilityExaminations = API.BE + "/examination/facility-examinations"
        static let exportCsv = API.BE + "/examination/export/csv"
    }
    
    // MARK: - Initialization
    init(networkService: NetworkServiceProtocol = DependencyInjection.shared.networkService) {
        self.networkService = networkService
    }

    // MARK: - Public Methods
    func getExamById(examId: String) async throws -> ExaminationDetailData {
        let response: APIResponse<Examination> = try await networkService
            .get(urlString: APIEndpoints.getExaminationById + examId.lowercased(), headers: nil)

        return ExaminationDetailData(
            examinationId: response.data.id,
            pic: response.data.PIC?.name ?? AppConstants.defaultUnknownValue,
            slideId: response.data.slideId,
            examinationGoal: response.data.goal?.rawValue ?? AppConstants.defaultNoGoalValue,
            type: response.data.preparationType?.rawValue ?? AppConstants.defaultNoTypeValue,
            dpjp: response.data.DPJP?.name ?? AppConstants.defaultUnknownValue
        )
    }

    func getAdminExamDetail(observationId: String) async throws -> AdminExaminationDetailData {
        let response: APIResponse<AdminExaminationDetailData> = try await networkService
            .get(urlString: APIEndpoints.getAdminExaminationDetail + observationId, headers: nil)
        
        return response.data
    }

    func getPatientById(patientId: String) async throws -> PatientDetailData {
        let response: APIResponse<Patient> = try await networkService.get(
            urlString: APIEndpoints.getPatientById + patientId.lowercased(),
            headers: nil
        )

        return PatientDetailData(
            patientId: response.data.id,
            name: response.data.name,
            nik: response.data.NIK,
            dob: response.data.DoB?.formattedDayMonthYear() ?? AppValue.empty,
            sex: response.data.sex.rawValue,
            bpjs: response.data.BPJS ?? AppValue.empty
        )
    }

    func submitExamination(
        videoFileURL: URL,
        examinationId: String,
        patientId: String
    ) async throws -> APIResponse<ForwardVideoToMLData> {
        let urlString = APIEndpoints.forwardVideoToML + "\(examinationId.lowercased())"

        return try await networkService.multipartFile(
            urlString: urlString,
            headers: UploadRequestContext.submissionId.map { id in
                ["Idempotency-Key": id, "X-Video-SHA256": UploadRequestContext.videoSHA256 ?? ""]
            },
            fileURL: videoFileURL,
            fieldName: "video",
            fileName: videoFileURL.lastPathComponent,
            mimeType: nil
        )
    }

    /// Calls the original entrypoint so existing interactor overrides keep working.
    func submitQueuedExamination(
        videoFileURL: URL, examinationId: String, patientId: String,
        submissionId: String, videoSHA256: String
    ) async throws -> APIResponse<ForwardVideoToMLData> {
        try await UploadRequestContext.$preservesHTTPMetadata.withValue(true) {
            try await UploadRequestContext.$submissionId.withValue(submissionId) {
                try await UploadRequestContext.$videoSHA256.withValue(videoSHA256) {
                    try await self.submitExamination(videoFileURL: videoFileURL, examinationId: examinationId, patientId: patientId)
                }
            }
        }
    }

    func fetchSubmissionReceipt(examinationId: String, submissionId: String) async throws -> AnalysisSubmissionReceipt {
        try await UploadRequestContext.$preservesHTTPMetadata.withValue(true) {
            let response: APIResponse<AnalysisSubmissionReceipt> = try await networkService.get(
                urlString: APIEndpoints.analysisSubmissions + examinationId.lowercased() + "/" + submissionId.lowercased(),
                headers: nil
            )
            guard (response.httpStatusCode ?? response.code) == 200 else { throw UploadProtocolFailure() }
            var receipt = response.data
            receipt.retryAfter = response.retryAfter
            return receipt
        }
    }

    func adminUpdateObservation(
        observationId: String,
        picId: String? = nil,
        archived: Bool? = nil
    ) async throws -> AdminObservationUpdateData {
        let body = AdminObservationUpdateBody(picId: picId, archived: archived)
        let response: APIResponse<AdminObservationUpdateData> = try await networkService.update(
            urlString: APIEndpoints.adminUpdateObservation + observationId.lowercased() + "/admin",
            headers: nil,
            body: body
        )
        return response.data
    }

    func getFacilityExaminations(filters: HistoryExamFilters) async throws -> FacilityExaminationListData {
        var components = URLComponents(string: APIEndpoints.facilityExaminations)
        components?.queryItems = filters.queryItems()
        guard let urlString = components?.url?.absoluteString else {
            throw URLError(.badURL)
        }

        let response: APIResponse<FacilityExaminationListData> = try await networkService.get(
            urlString: urlString,
            headers: nil
        )
        return response.data
    }

    func downloadFacilityExaminationsCsv(filters: HistoryExamFilters) async throws -> URL {
        guard let token = KeychainHelper.string(for: .accessToken) else {
            throw URLError(.userAuthenticationRequired)
        }

        var components = URLComponents(string: APIEndpoints.exportCsv)
        components?.queryItems = filters.queryItems()
        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("facility-examinations-\(UUID().uuidString).csv")
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }
}

// MARK: - Data Models
struct ExaminationDetailData {
    let examinationId: String
    let pic: String
    let slideId: String
    let examinationGoal: String
    let type: String
    let dpjp: String
}

struct PatientDetailData {
    let patientId: String
    let name: String
    let nik: String
    let dob: String
    let sex: String
    let bpjs: String
}

struct ForwardVideoToMLData: Decodable {
    let examinationId: String?
    let statusExamination: StatusType?
    let statusML: String?
    var submissionId: String?
    var attemptId: String?
    var state: String?
    var submissionReceiptVersion: Int?
}

struct AnalysisSubmissionReceipt: Decodable {
    let submissionId: String
    let examinationId: String
    let state: String
    let attemptId: String?
    let submissionReceiptVersion: Int
    var retryAfter: Date? = nil

    func matches(examinationId: String, submissionId: String) -> Bool {
        self.examinationId.lowercased() == examinationId.lowercased()
            && self.submissionId.lowercased() == submissionId.lowercased()
            && submissionReceiptVersion == 1
            && ["not_found", "pending", "accepted", "retryable"].contains(state)
            && (state == "not_found" || attemptId.flatMap(UUID.init(uuidString:)) != nil)
    }
}
