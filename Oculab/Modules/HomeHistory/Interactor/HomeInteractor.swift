//
//  HomeInteractor.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 18/10/24.
//

import Foundation

class HomeInteractor {
    private let examinationURL = API.BE + "/examination"
    private let apiURL = API.BE + "/examination/get-number-of-examinations"
    private let apiGetAllData = API.BE + "/examination/get-all-examinations/"
    private let apiGetFinishedExaminationCardData = API.BE + "/examination/get-finished-examination-card-data/"

    func getStatisticExamination() async throws -> ExaminationStatistic {
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw NSError(
                domain: "UserIDNotFound",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "User ID not found"]
            )
        }

        let response: APIResponse<ExaminationStatistic> = try await NetworkHelper.shared
            .get(urlString: examinationURL + "/get-statistics-todo-lab/" + userId)

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

        let response: APIResponse<[Examination]> = try await NetworkHelper.shared
            .get(urlString: apiGetAllData + userId)

        let examinationDataCard = response.data.map { exam -> ExaminationCardData in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMMM yyyy"

            let formattedDate = dateFormatter.string(from: exam.examinationPlanDate ?? Date())
            let formattedDate2 = dateFormatter.string(from: exam.examinationDate ?? Date())

            return ExaminationCardData(
                examinationId: exam._id,
                statusExamination: exam.statusExamination,
                datePlan: formattedDate,
                date: formattedDate2,
                slideId: exam.slideId,
                patientName: exam.patientName ?? "",
                patientDob: exam.patientDoB ?? "",
                patientId: exam.patientId ?? "",
                picName: exam.picName ?? "",
                picId: exam.picId ?? "",
                finalGradingResult: exam.expertResult?.finalGrading.rawValue ?? GradingType.unknown.rawValue,
                dpjpName: exam.dpjpName ?? ""
            )
        }

        return examinationDataCard
    }
    
    func getFinishedDataCard(date: String) async throws -> [FinishedExaminationCardData] {
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw NSError(domain: "UserIDNotFound", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])
        }

        let fullURL = apiGetFinishedExaminationCardData + userId + "/" + date

        do {
            let response: APIResponse<[Examination]> = try await NetworkHelper.shared.get(urlString: fullURL)
            
            return response.data.map { exam in
                FinishedExaminationCardData(
                    examinationId: exam._id,
                    patientId: exam.patientId ?? "",
                    slideId: exam.slideId,
                    patientName: exam.patientName ?? "",
                    patientDob: exam.patientDoB ?? "",
                    dpjpName: exam.dpjpName ?? "",
                    finalGradingResult: exam.finalGradingResult ??
                                      exam.expertResult?.finalGrading.rawValue ??
                                      GradingType.unknown.rawValue
                )
            }
            
        } catch {
            // Handle "no data found" as empty result
            if let networkError = error as? NetworkError,
               case .apiError(let apiResponse) = networkError,
               apiResponse.data.errorType == "VALIDATION_ERROR" &&
               apiResponse.data.description.contains("No finished examinations found") {
                return []
            }
            
            throw error
        }
    
//    func getFinishedDataCard(date: String) async throws -> [FinishedExaminationCardData] {
//        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
//            throw NSError(
//                domain: "UserIDNotFound",
//                code: -1,
//                userInfo: [NSLocalizedDescriptionKey: "User ID not found"]
//            )
//        }
//
//        let response: APIResponse<[Examination]> = try await NetworkHelper.shared
//            .get(urlString: apiGetFinishedExaminationCardData + userId + "/" + date)
//        
//        let fullURL = apiGetFinishedExaminationCardData + userId + "/" + date
//            print("🔗 API URL: \(fullURL)")
//
//        let examinationDataCard = response.data.map { exam -> FinishedExaminationCardData in
//
//            return FinishedExaminationCardData(
//                examinationId: exam._id,
//                patientId: exam.patientId ?? "",
//                slideId: exam.slideId,
//                patientName: exam.patientName ?? "",
//                patientDob: exam.patientDoB ?? "",
//                dpjpName: exam.dpjpName ?? "",
//                finalGradingResult: exam.finalGradingResult ?? exam.expertResult?.finalGrading.rawValue ?? GradingType.unknown.rawValue
//            )
//        }
//
//        return examinationDataCard
    }
}

