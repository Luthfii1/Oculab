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
    private let apiGetAllData = API.BE + "/examination/get-all-examinations"

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
        let response: APIResponse<[Examination]> = try await NetworkHelper.shared.get(urlString: apiGetAllData)

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
}
