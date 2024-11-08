//
//  InputPatientInteractor.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 07/11/24.
//

import Foundation

class InputPatientInteractor {
    private let apiGetAllUser = API.BE + "/user/get-all-pics"
    private let apiGetAllPatient = API.BE + "/patient/get-all-patients"
    let urlGetDataPatient = API.BE + "/patient/get-patient-by-id/"
    let urlGetDataUser = API.BE + "/user/get-user-data-by-id/"

    func getAllUser(completion: @escaping (Result<[User], NetworkErrorType>) -> Void) {
        NetworkHelper.shared.get(urlString: apiGetAllUser) { (result: Result<
            APIResponse<[User]>,
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

    func getAllPatient(completion: @escaping (Result<[Patient], NetworkErrorType>) -> Void) {
        NetworkHelper.shared.get(urlString: apiGetAllPatient) { (result: Result<
            APIResponse<[Patient]>,
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

    func getPatientById(
        patientId: String,
        completion: @escaping (Result<Patient, NetworkErrorType>) -> Void
    ) {
        print(urlGetDataPatient + patientId.lowercased())

        NetworkHelper.shared.get(urlString: urlGetDataPatient + patientId.lowercased()) { (result: Result<
            APIResponse<Patient>,
            NetworkErrorType
        >) in
            DispatchQueue.main.async {
                switch result {
                case let .success(apiResponse):

                    completion(.success(apiResponse.data))

                case let .failure(error):
                    completion(.failure(error))
                    print(error)
                }
            }
        }
    }

    func getUserById(
        userId: String,
        completion: @escaping (Result<User, NetworkErrorType>) -> Void
    ) {
        NetworkHelper.shared.get(urlString: urlGetDataUser + userId.lowercased()) { (result: Result<
            APIResponse<User>,
            NetworkErrorType
        >) in
            DispatchQueue.main.async {
                switch result {
                case let .success(apiResponse):

                    completion(.success(apiResponse.data))

                case let .failure(error):
                    completion(.failure(error))
                    print(error)
                }
            }
        }
    }
}
