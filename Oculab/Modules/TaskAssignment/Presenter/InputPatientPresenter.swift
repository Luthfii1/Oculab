//
//  InputPatientPresenter.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 07/11/24.
//

import Foundation
import SwiftUI

class InputPatientPresenter: ObservableObject {
    var interactor: InputPatientInteractor? = InputPatientInteractor()

    @Published var selectedPIC: String = AppValue.empty
    @Published var selectedPatient: String = AppValue.empty {
        didSet {
            print("patient: \(selectedPatient)")
        }
    }

    @Published var isAddingNewPatient: Bool = false
    @Published var isError: Bool = false
    @Published var errorMessage: String = AppValue.empty

    @Published var isAddingName: Bool = false
    @Published var selectedSex: String = AppValue.empty
    @Published var selectedDoB: Date = .init()
    @Published var BPJSnumber: String = AppValue.empty

    @Published var isUserLoading = false
    @Published var isPatientLoading = false

    @Published var picName: [(String, String)] = []
    @Published var patientNameDoB: [(String, String)] = []

    @Published var patient: Patient = .init(
        _id: UUID().uuidString.lowercased(),
        name: AppValue.empty,
        NIK: AppValue.empty,
        DoB: Date(),
        sex: .UNKNOWN
    )
    @Published var pic: User = .init(_id: AppValue.empty, name: AppValue.empty, role: .ADMIN)

    @Published var patientFound: Bool = false {
        didSet {
            if patientFound {
                print("dob: \(String(describing: patient.DoB))")
                print("sex: \(patient.sex)")
                print("bpjs: \(String(describing: patient.BPJS))")
                selectedDoB = patient.DoB ?? Date()
                if patient.sex == .MALE {
                    selectedSex = AppPatient.Gender.male
                } else if patient.sex == .FEMALE {
                    selectedSex = AppPatient.Gender.female
                }
                
                BPJSnumber = patient.BPJS ?? AppValue.empty
            }
        }
    }

    @Published var examination: Examination = .init(
        _id: UUID().uuidString.lowercased(),
        goal: nil,
        preparationType: nil,
        slideId: AppValue.empty,
        recordVideo: nil,
        examinationDate: Date(),
        examinationPlanDate: Date(),
        statusExamination: .NOTSTARTED
    )

    @Published var examination2: Examination = .init(
        _id: UUID().uuidString.lowercased(),
        goal: nil,
        preparationType: nil,
        slideId: AppValue.empty,
        recordVideo: nil,
        examinationDate: Date(),
        examinationPlanDate: Date(),
        statusExamination: .NOTSTARTED
    )

    @MainActor
    func getAllUser() async {
        isUserLoading = true
        defer { isUserLoading = false }

        do {
            let response = try await interactor?.getAllUser()
            if let data = response {
                for pic in data {
                    picName.append((pic.name, pic._id))
                }
            }
        } catch {
            // Handle error
            switch error {
            case let NetworkError.apiError(apiResponse):
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")

            case let NetworkError.networkError(message):
                print("Network error: \(message)")

            default:
                print("Unknown error: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func getAllPatient() async {
        isPatientLoading = true
        defer {
            isPatientLoading = false
        }

        do {
            let response = try await interactor?.getAllPatient()

            if let response {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd/MM/yyyy"

                for patient in response {
                    let formattedDoB = patient.DoB.map { dateFormatter.string(from: $0) } ?? AppValue.empty
                    patientNameDoB.append((patient.name +  String(formattedDoB), patient._id))
                }
            }
        } catch {
            // Handle error
            switch error {
            case let NetworkError.apiError(apiResponse):
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")

            case let NetworkError.networkError(message):
                print("Network error: \(message)")

            default:
                print("Unknown error: \(error.localizedDescription)")
            }
        }
    }

    func clearForm() {
        patientFound = false
        patient = Patient(
            _id: UUID().uuidString.lowercased(),
            name: AppValue.empty,
            NIK: AppValue.empty,
            DoB: Date(),
            sex: .UNKNOWN
        )
        selectedDoB = Date()
        selectedSex = AppValue.empty
        BPJSnumber = AppValue.empty
    }

    @MainActor
    func getPatientById(patientId: String) async {
        isPatientLoading = true
        defer {
            isPatientLoading = false
        }

        do {
            let response = try await interactor?.getPatientById(patientId: patientId)

            if let patient = response {
                self.patient = patient
                patientFound = true
            }
        } catch {
            clearForm()
            // Handle error
            switch error {
            case let NetworkError.apiError(apiResponse):
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")

            case let NetworkError.networkError(message):
                print("Network error: \(message)")

            default:
                print("Unknown error: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func getUserById(userId: String) async {
        isUserLoading = true
        defer {
            isUserLoading = false
        }

        do {
            let response = try await interactor?.getUserById(userId: userId)

            if let user = response {
                pic = user
            }
        } catch {
            // Handle error
            switch error {
            case let NetworkError.apiError(apiResponse):
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")

            case let NetworkError.networkError(message):
                print("Network error: \(message)")

            default:
                print("Unknown error: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func newExam() {
        Task {
            if !patientFound {
                let success = await addNewPatient()
                if success {
                    navigateToNewExam()
                } else {
                    print("Failed to add new patient.")
                }
            } else {
                print("here")
                navigateToNewExam()
            }
        }
    }

    @MainActor
    func addNewPatient() async -> Bool {
        print(patient._id)
        print(patient.name)
        print(patient.BPJS ?? AppValue.empty)
        print(patient.NIK)
        print(patient.DoB ?? AppValue.empty)

        do {
            patient.name = selectedPatient
            let response = try await interactor?.addNewPatient(patient: patient)

            if let response {
                patient = response
                return true
            }
        } catch {
            // Handle error
            switch error {
            case let NetworkError.apiError(apiResponse):
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")

            case let NetworkError.networkError(message):
                print("Network error: \(message)")

            default:
                print("Unknown error: \(error.localizedDescription)")
            }
        }
        return false
    }

    private func navigateToNewExam() {
        Router.shared.navigateTo(.newExam(patientId: patient._id, picId: pic._id))
    }

    @MainActor
    func submitExamination() async {
        let DPJPId = UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue)
        
        var examinationsToSend: [ExaminationRequest] = []
        
        let exam2HasData = examination2.preparationType != nil || !examination2.slideId.isEmpty
        if exam2HasData {
            guard let prepType1 = examination.preparationType,
                  !examination.slideId.isEmpty else {
                isError = true
                errorMessage = AppTextTaskAssignInputExam.warningFirstExamShouldBeFilled
                return
            }
            
            guard let prepType2 = examination2.preparationType,
                  !examination2.slideId.isEmpty else {
                isError = true
                errorMessage = AppTextTaskAssignInputExam.warningSecondExamShouldBeFilled
                return
            }
            
            guard examination.slideId != examination2.slideId else {
                isError = true
                errorMessage = AppTextTaskAssignInputExam.warningSlideIDsMustBeDifferent
                return
            }
            
            let examReq1 = ExaminationRequest(
                _id: examination._id,
                goal: examination.goal,
                preparationType: prepType1,
                slideId: examination.slideId,
                examinationDate: examination.examinationDate,
                PIC: pic._id,
                DPJP: DPJPId,
                examinationPlanDate: examination.examinationPlanDate
            )
            
            let examReq2 = ExaminationRequest(
                _id: examination2._id,
                goal: examination.goal,  // Same goal
                preparationType: prepType2,
                slideId: examination2.slideId,
                examinationDate: examination2.examinationDate,
                PIC: pic._id,
                DPJP: DPJPId,
                examinationPlanDate: examination2.examinationPlanDate
            )
            examinationsToSend.append(examReq1)
            examinationsToSend.append(examReq2)
        } else {
            guard let goal1 = examination.goal,
                  let prepType1 = examination.preparationType,
                  !examination.slideId.isEmpty else {
                isError = true
                errorMessage = AppTextTaskAssignInputExam.warningExaminationMustBeFilled
                return
            }
            
            let examReq1 = ExaminationRequest(
                _id: examination._id,
                goal: goal1,
                preparationType: prepType1,
                slideId: examination.slideId,
                examinationDate: examination.examinationDate,
                PIC: pic._id,
                DPJP: DPJPId,
                examinationPlanDate: examination.examinationPlanDate
            )
            examinationsToSend.append(examReq1)
        }

        do {
            guard let response = try await interactor?.addNewExamination(
                patientId: patient._id,
                examinations: examinationsToSend
            ) else {
                isError = true
                errorMessage = AppTextTaskAssignInputExam.errorMessageFailedToGetResponse
                return
            }

            let createdExaminations = response.examinations
            let expectedCount = examinationsToSend.count

            guard createdExaminations.count == expectedCount else {
                isError = true
                errorMessage = AppTextTaskAssignInputExam.errorMessageNotAllExamsCreated
                return
            }

            guard createdExaminations.allSatisfy({ !$0._id.isEmpty && !$0.slideId.isEmpty }) else {
                isError = true
                errorMessage = AppTextTaskAssignInputExam.errorMessageExamsContainInvalidData
                return
            }

            Router.shared.popToRoot()
        } catch {
            isError = true
            // Handle error
            switch error {
            case let NetworkError.apiError(apiResponse):
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")
                errorMessage = apiResponse.data.description

            case let NetworkError.networkError(message):
                print("Network error: \(message)")
                errorMessage = message

            default:
                print("Unknown error: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct ExaminationRequest: Encodable {
    var _id: String?
    var goal: ExamGoalType?
    var preparationType: ExamPreparationType?
    var slideId: String?
    var examinationDate: Date?
    var PIC: String?
    var DPJP: String?
    var examinationPlanDate: Date?

    enum CodingKeys: CodingKey {
        case _id
        case goal
        case preparationType
        case slideId
        case examinationDate
        case PIC
        case DPJP
        case examinationPlanDate
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(_id, forKey: ._id)
        try container.encode(goal, forKey: .goal)
        try container.encode(preparationType, forKey: .preparationType)
        try container.encode(slideId, forKey: .slideId)
        try container.encode(PIC, forKey: .PIC)
        try container.encode(DPJP, forKey: .DPJP)

        if let examinationDate = examinationDate {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateString = dateFormatter.string(from: examinationDate)
            try container.encode(dateString, forKey: .examinationDate)
        }

        if let examinationPlanDate = examinationPlanDate {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateString = dateFormatter.string(from: examinationPlanDate)
            try container.encode(dateString, forKey: .examinationPlanDate)
        }
    }
}
