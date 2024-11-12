//
//  HomeInteractor.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 18/10/24.
//

import Foundation

class HomeInteractor {
    private let apiURL = API.BE + "/examination/get-number-of-examinations"
    private let apiGetAllData = API.BE + "/examination/get-all-examinations"

    func getStatisticExamination(completion: @escaping (Result<ExaminationStatistic, ApiErrorData>) -> Void) {
        NetworkHelper.shared.get(urlString: API.BE + "/examination/get-number-of-examinations") { (result: Result<
            APIResponse<ExaminationStatistic>,
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

    func getAllData(completion: @escaping (Result<[ExaminationCardData], ApiErrorData>) -> Void) {
        NetworkHelper.shared.get(urlString: apiGetAllData) { (result: Result<
            APIResponse<[Examination]>,
            APIResponse<ApiErrorData>
        >) in
            DispatchQueue.main.async {
                switch result {
                case let .success(apiResponse):
                    let examinationDataCard = apiResponse.data.map { exam -> ExaminationCardData in
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
                    completion(.success(examinationDataCard))

                case let .failure(error):
                    completion(.failure(error.data))
                    print(error)
                }
            }
        }
    }
}
