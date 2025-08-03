//
//  HomeInteractor.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 18/10/24.
//

import Foundation

class HomeInteractor {
    private let networkService: NetworkService

    init(networkService: NetworkService = AlamofireNetworkService()) {
        self.networkService = networkService
    }
    
    private let examinationURL = API.BE + "/examination"
    private let apiURL = API.BE + "/examination/get-number-of-examinations"
    private let apiGetAllData = API.BE + "/examination/get-all-examinations/"
    private let apiGetAllDataAdmin = API.BE_LOCAL + "/examination/get-examination-card-data-admin/"
    private let apiGetFinishedExaminationCardData = API.BE + "/examination/get-finished-examination-card-data/"
    private let apiGetUnfinishedExaminationCardData = API.BE + "/examination/get-unfinished-examination-card-data/"

    func getStatisticExamination() async throws -> ExaminationStatistic {
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw NSError(
                domain: "UserIDNotFound",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "User ID not found"]
            )
        }

        let response: APIResponse<ExaminationStatistic> = try await networkService
            .get(urlString: examinationURL + "/get-statistics-todo-lab/" + userId, headers: nil)

        return response.data
    }

    func getAllData() async throws -> [ExaminationCardData] {
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw NSError(
                domain: "UserIDNotFound",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "User ID not found"]
            )
        }
        let fullURL = apiGetUnfinishedExaminationCardData + userId

        let response: APIResponse<[UnfinishedExaminationCardData]> = try await networkService.get(urlString: fullURL, headers: nil)

        let unfinishedExaminationResponse = response.data.map { exam in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMMM yyyy"
            
            var formattedDate = ""
            if let dateString = exam.examinationPlanDate {
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                if let date = isoFormatter.date(from: dateString) {
                    formattedDate = date.formattedDayMonthYearTime()
                } else {
                    // Fallback for basic ISO format
                    let basicFormatter = ISO8601DateFormatter()
                    if let date = basicFormatter.date(from: dateString) {
                        formattedDate = date.formattedDayMonthYearTime()
                    } else {
                        formattedDate = "Invalid Date"
                    }
                }
            }
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
    
    func getFinishedDataCard(date: String) async throws -> [FinishedExaminationCardData] {
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw NSError(domain: "UserIDNotFound", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])
        }

        let fullURL = apiGetFinishedExaminationCardData + userId + "/" + date

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
