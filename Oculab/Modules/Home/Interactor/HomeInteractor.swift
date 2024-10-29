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
    func getStatisticExamination(completion: @escaping (Result<ExaminationStatistic, NetworkErrorType>) -> Void) {
        NetworkHelper.shared.get(urlString: API.BE_Prod + "/examination/get-number-of-examinations") { (result: Result<
            APIResponse<ExaminationStatistic>,
            NetworkErrorType
        >) in
            DispatchQueue.main.async {
                switch result {
                case let .success(apiResponse):
                    completion(.success(apiResponse.data))
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: EXAMPLE ANOTHER METHOD FOR POST
    func createNewPatient(completion: @escaping (Result<Patient, NetworkErrorType>) -> Void) {
        let bodyPatient = Patient(name: "Luthfi Baru", NIK: "217509123", DoB: Date(), sex: .MALE)

        NetworkHelper.shared
            .post(
                urlString: API.BE_Prod + "/patient/create-new-patient",
                body: bodyPatient
            ) { (result: Result<APIResponse<Patient>, NetworkErrorType>) in
                DispatchQueue.main.async {
                    switch result {
                    case let .success(response):
                        completion(.success(response.data))
                    case let .failure(error):
                        print("error interactor")
                        completion(.failure(error))
                    }
                }
            }
    }

    // MARK: EXAMPLE ANOTHER METHOD FOR UPDATE AND DELETE
//     // Updating an existing examination statistic
//     func updateStatisticExamination(statisticId: String, updatedStatistic: ExaminationStatistic, completion:
//     @escaping (Result<ExaminationStatistic, NetworkErrorType>) -> Void) {
//         let urlString = API.BE + "/examination/update-statistic/\(statisticId)"
//         NetworkHelper.shared.put(urlString: urlString, body: updatedStatistic) { (result: Result<
//             APIResponse<ExaminationStatistic>,
//             NetworkErrorType
//         >) in
//             DispatchQueue.main.async {
//                 switch result {
//                 case let .success(apiResponse):
//                     completion(.success(apiResponse.data))
//                 case let .failure(error):
//                     completion(.failure(error))
//                 }
//             }
//         }
//     }
//
//     // Deleting an examination statistic
//     func deleteStatisticExamination(statisticId: String, completion: @escaping (Result<Void, NetworkErrorType>) ->
//     Void) {
//         let urlString = API.BE + "/examination/delete-statistic/\(statisticId)"
//         NetworkHelper.shared.delete(urlString: urlString) { (result: Result<
//             APIResponse<Void>,
//             NetworkErrorType
//         >) in
//             DispatchQueue.main.async {
//                 switch result {
//                 case .success:
//                     completion(.success(()))
//                 case let .failure(error):
//                     completion(.failure(error))
//                 }
//             }
//         }
//     }

    func getAllData(completion: @escaping (Result<[ExaminationCardData], Error>) -> Void) {
        // Simulating API data response
        let jsonData = DummyJSON().examinationCards

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601

            let examinationData = try decoder.decode([Examination].self, from: jsonData)

            let examinationDataCard = examinationData.map { exam -> ExaminationCardData in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd MMMM yyyy"

                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"

                let formattedDate = dateFormatter.string(from: exam.examinationDate)
                let formattedTime = timeFormatter.string(from: exam.examinationDate)

                return ExaminationCardData(
                    examinationId: exam._id.uuidString,
                    statusExamination: exam.statusExamination,
                    imagePreview: exam.imagePreview,
                    date: formattedDate,
                    time: formattedTime,
                    slideId: exam.slideId
                )
            }
            completion(.success(examinationDataCard))

        } catch {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            print("Failed to decode data: \(error)")
        }
    }
}
