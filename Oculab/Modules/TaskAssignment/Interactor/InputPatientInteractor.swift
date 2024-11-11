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
    let urlCreatePatient = API.BE + "/patient/create-new-patient/"

    func getAllUser(completion: @escaping (Result<[User], ApiErrorData>) -> Void) {
        NetworkHelper.shared.get(urlString: apiGetAllUser) { (result: Result<
            APIResponse<[User]>,
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

    func getAllPatient(completion: @escaping (Result<[Patient], ApiErrorData>) -> Void) {
        NetworkHelper.shared.get(urlString: apiGetAllPatient) { (result: Result<
            APIResponse<[Patient]>,
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

    func getPatientById(
        patientId: String,
        completion: @escaping (Result<Patient, ApiErrorData>) -> Void
    ) {
        print(urlGetDataPatient + patientId.lowercased())

        NetworkHelper.shared.get(urlString: urlGetDataPatient + patientId.lowercased()) { (result: Result<
            APIResponse<Patient>,
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

    func getUserById(
        userId: String,
        completion: @escaping (Result<User, ApiErrorData>) -> Void
    ) {
        NetworkHelper.shared.get(urlString: urlGetDataUser + userId.lowercased()) { (result: Result<
            APIResponse<User>,
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

    func addNewPatient(
        patient: Patient,
        completion: @escaping (Result<Patient, ApiErrorData>) -> Void
    ) {
        NetworkHelper.shared.post(urlString: urlCreatePatient, body: patient) { (result: Result<
            APIResponse<Patient>, APIResponse<ApiErrorData>
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
}

struct ErrorMessage: Decodable {
    var errorType: String
    var description: String
}
