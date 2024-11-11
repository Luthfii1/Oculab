//
//  HomeInteractor.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 18/10/24.
//

import Foundation

struct ExaminationStatistic: Decodable {
    var numberOfPositive: Int = 0
    var numberOfNegative: Int = 0
}

class HomeInteractor {
    private let apiURL = API.BE + "/examination/get-number-of-examinations"
    private let apiGetAllData = API.BE + "/examination/get-all-examinations"

    func getStatisticExamination(completion: @escaping (Result<ExaminationStatistic, ApiErrorData>) -> Void) {
        NetworkHelper.shared.get(urlString: API.BE + "/examination/get-number-of-examinations") { (result: Result<
            APIResponse<ExaminationStatistic>, APIResponse<ApiErrorData>
        >) in
            DispatchQueue.main.async {
                switch result {
                case let .success(successReponse):
                    completion(.success(successReponse.data))

                case let .failure(error):
                    completion(.failure(error.data))
                }
            }
        }
    }

    func getAllData(completion: @escaping (Result<[ExaminationCardData], ApiErrorData>) -> Void) {
        NetworkHelper.shared.get(urlString: apiGetAllData) { (result: Result<
            APIResponse<[Examination]>,
            APIResponse<ApiErrorData>
        >) in
            DispatchQueue.main.async {
                switch result {
                case let .success(successResponse):
                    let examinationDataCard = successResponse.data.map { exam -> ExaminationCardData in
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "dd MMMM yyyy"

                        let formattedDate = dateFormatter.string(from: exam.examinationPlanDate ?? Date())
                        return ExaminationCardData(
                            examinationId: exam._id.uuidString,
                            statusExamination: exam.statusExamination,
                            imagePreview: "",
                            datePlan: formattedDate,
                            slideId: exam.slideId,
                            patientName: exam.patientName ?? "",
                            patientDob: exam.patientDoB ?? "",
                            patientId: exam.patientId ?? "")
                    }
                    completion(.success(examinationDataCard))

                case let .failure(error):
                    completion(.failure(error.data))
                }
            }
        }
    }
}
