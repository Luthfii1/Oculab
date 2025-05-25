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
                picId: exam.picId ?? ""
            )
        }

        return examinationDataCard
    }
    
//    func getFinishedExaminationCardData(
//        date: String
//    ) async throws -> [FinishedExaminationCardData] {
//        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
//            throw NSError(
//                domain: "UserIDNotFound",
//                code: -1,
//                userInfo: [NSLocalizedDescriptionKey: "User ID not found"]
//            )
//        }
//        
//        print("userId:", userId)
//        print("date: ", date)
//        print("api: ", apiGetFinishedExaminationCardData + userId + "/" + date)
//
//        do {
//            let response: APIResponse<[FinishedExaminationCardData]> = try await NetworkHelper.shared
//                .get(urlString: apiGetFinishedExaminationCardData + userId + "/" + date)
//            
//            print("RESPONSE API: ", response.data)
//            return response.data
//            
//        } catch {
//            // Handle validation errors by returning empty array instead of throwing
//            if let networkError = error as? NetworkError,
//               case .apiError(let apiResponse) = networkError,
//               apiResponse.data.errorType == "VALIDATION_ERROR" {
//                print("No data found for date \(date) - returning empty array")
//                return []
//            }
//            
//            // For other errors, still throw
//            print("API call failed with error: \(error)")
//            throw error
//        }
//    }
    
//    func getFinishedExaminationCardData(
//        date: String
//    ) async throws -> [FinishedExaminationCardData] {
//        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
//            throw NSError(
//                domain: "UserIDNotFound",
//                code: -1,
//                userInfo: [NSLocalizedDescriptionKey: "User ID not found"]
//            )
//        }
//        
//        print("userId:", userId)
//        print("date: ", date)
//        
//        print("api: ", apiGetFinishedExaminationCardData + userId + "/" + date)
//
//
//        let response: APIResponse<[FinishedExaminationCardData]> = try await NetworkHelper.shared
//            .get(urlString: apiGetFinishedExaminationCardData + userId + "/" + date)
//        
////        print("RESPONSE API: ", response.data)
//        
//        let finishedExaminationCardData = response.data.map { exam -> FinishedExaminationCardData in
//
//            return FinishedExaminationCardData(
//                id: exam.id,
//                patientId: exam.patientId,
//                slideId: exam.slideId,
//                patientName: exam.patientName,
//                patientDob: exam.patientDob,
//                dpjpName: exam.dpjpName,
//                finalGradingResult: exam.finalGradingResult
//            )
//        }
//        
//        print("data fetched: ", response.data)

//        return response.data
//        return finishedExaminationCardData;
//    }
//    func getFinishedExaminationCardData(date: String) async throws -> [FinishedExaminationCardData] {
//        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
//            throw NSError(
//                domain: "UserIDNotFound",
//                code: -1,
//                userInfo: [NSLocalizedDescriptionKey: "User ID not found"]
//            )
//        }
//        
//        // Construct URL with date parameter if needed
//        let urlString = apiGetFinishedExaminationCardData + userId + "/" + date
//        
//        let response: APIResponse<[FinishedExaminationCardData]> = try await NetworkHelper.shared
//            .get(urlString: urlString)
//        
//        return response.data
//    }
    
    func getFinishedExaminationCardData(date: String) async throws -> [FinishedExaminationCardData] {
        guard let userId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue) else {
            throw NSError(
                domain: "UserIDNotFound",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "User ID not found"]
            )
        }
        
        let urlString = apiGetFinishedExaminationCardData + userId + "/" + date
        
        do {
            let response: APIResponse<[FinishedExaminationCardData]> = try await NetworkHelper.shared
                .get(urlString: urlString)
            return response.data
            
        } catch NetworkError.apiError(let errorResponse) where
            errorResponse.data.errorType == "VALIDATION_ERROR" &&
            errorResponse.data.description.contains("No finished examinations found") {
            // This is expected when no data exists for the date
            return []
            
        } catch {
            // Re-throw all other errors
            throw error
        }
    }
    
}
