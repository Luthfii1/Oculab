//
//  HomeInteractor.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 18/10/24.
//

import Foundation

class HomeInteractor {
    // MARK: - Dependencies
    private let networkService: NetworkServiceProtocol

    // MARK: - API Endpoints
    private struct APIEndpoints {
        static let examination = API.BE + "/examination"
        static let statistics = examination + "/get-statistics-todo-lab/"
        static let numberOfExaminations = examination + "/get-number-of-examinations"
        static let allExaminations = examination + "/get-all-examinations/"
        static let adminExaminations = examination + "/get-examination-card-data-admin/"
        static let finishedExaminations = examination + "/get-finished-examination-card-data/"
        static let unfinishedExaminations = examination + "/get-unfinished-examination-card-data/"
    }

    // MARK: - Initialization
    init(networkService: NetworkServiceProtocol = DependencyInjection.shared.networkService) {
        self.networkService = networkService
    }

    // MARK: - Public Methods
    func getStatisticExamination() async throws -> ExaminationStatistic {
        let userId = try getUserId()
        
        let response: APIResponse<ExaminationStatistic> = try await networkService
            .get(urlString: APIEndpoints.statistics + userId, headers: nil)

        return response.data
    }

    func getAllData() async throws -> [ExaminationCardData] {
        let userId = try getUserId()
        let fullURL = APIEndpoints.unfinishedExaminations + userId

        let response: APIResponse<[UnfinishedExaminationCardData]> = try await networkService.get(urlString: fullURL, headers: nil)

        let unfinishedExaminationResponse = response.data.map { exam in
            let formattedDate = formatExaminationDate(exam.examinationPlanDate)
            
            return ExaminationCardData(
                examinationId: exam.id,
                statusExamination: exam.statusExamination,
                datePlan: formattedDate,
                date: "",
                slideId: exam.slideId,
                patientName: exam.patientName,
                patientDob: exam.patientDob ?? "",
                patientId: exam.patientId,
                picName: exam.picName ?? "",
                picId: "",
                finalGradingResult: GradingType.unknown.rawValue,
                dpjpName: exam.dpjpName ?? ""
            )
        }
        return unfinishedExaminationResponse
    }
    
    func getAllDataAdmin() async throws -> [ExaminationCardData] {
        let userId = try getUserId()
        let fullURL = APIEndpoints.adminExaminations + userId

        let response: APIResponse<[AdminExaminationCardData]> = try await networkService.get(urlString: fullURL, headers: nil)

        let adminExaminationResponse = response.data.map { exam in
            let formattedDate = formatExaminationDate(exam.examinationPlanDate)
            
            return ExaminationCardData(
                examinationId: exam.observationId,
                statusExamination: .NOTSTARTED, // Default status for admin data
                datePlan: formattedDate,
                date: "",
                slideId: "", // Not provided in admin response
                patientName: exam.patientName,
                patientDob: exam.patientDob ?? "",
                patientId: exam.patientId,
                picName: exam.picName ?? "",
                picId: "",
                finalGradingResult: GradingType.unknown.rawValue,
                dpjpName: exam.dpjpName ?? ""
            )
        }
        return adminExaminationResponse
    }

    func getFinishedDataCard(date: String) async throws -> [FinishedExaminationCardData] {
        let userId = try getUserId()
        let fullURL = APIEndpoints.finishedExaminations + userId + "/" + date

        let response: APIResponse<[FinishedExaminationCardData]> = try await networkService.get(urlString: fullURL, headers: nil)

        let finishedExaminationResponse = response.data.map { exam in
            return FinishedExaminationCardData(
                examinationId: exam.id,
                patientId: exam.patientId,
                slideId: exam.slideId,
                patientName: exam.patientName,
                patientDob: exam.patientDob,
                dpjpName: exam.dpjpName ?? "",
                finalGradingResult: exam.finalGradingResult
            )
        }
        return finishedExaminationResponse
    }
}

// MARK: - Helper Methods
extension HomeInteractor {
    private func getUserId() throws -> String {
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw NSError(
                domain: "UserIDNotFound",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "User ID not found"]
            )
        }
        return userId
    }
    
    private func formatExaminationDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "" }
        
        // Try with fractional seconds first
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: dateString) {
            return date.formattedDayMonthYearTime()
        }
        
        // Fallback for basic ISO format
        let basicFormatter = ISO8601DateFormatter()
        if let date = basicFormatter.date(from: dateString) {
            return date.formattedDayMonthYearTime()
        }
        
        return "Invalid Date"
    }
}
