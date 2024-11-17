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

    @Published var selectedPIC: String = ""
    @Published var selectedPatient: String = "" {
        didSet {
            print("patient: \(selectedPatient)")
        }
    }

    @Published var isAddingNewPatient: Bool = false

    @Published var isAddingName: Bool = false
    @Published var selectedSex: String = ""
    @Published var selectedDoB: Date = .init()
    @Published var BPJSnumber: String = ""

    @Published var isUserLoading = false
    @Published var isPatientLoading = false

    @Published var picName: [(String, String)] = []
    @Published var patientNameDoB: [(String, String)] = []

    @Published var patient: Patient = .init(
        _id: UUID().uuidString.lowercased(),
        name: "",
        NIK: "",
        DoB: Date(),
        sex: .UNKNOWN
    )
    @Published var pic: User = .init(_id: "", name: "", role: .ADMIN)

    @Published var patientFound: Bool = false {
        didSet {
            if patientFound {
                print("dob: \(String(describing: patient.DoB))")
                print("sex: \(patient.sex)")
                print("bpjs: \(String(describing: patient.BPJS))")
                selectedDoB = patient.DoB ?? Date()
                if patient.sex == .MALE {
                    selectedSex = "Laki-laki"
                } else if patient.sex == .FEMALE {
                    selectedSex = "Perempuan"
                }
                if patient.BPJS != nil {
                    BPJSnumber = String(describing: patient.BPJS)
                } else {
                    BPJSnumber = "Doesn't have BPJS"
                }
            }
        }
    }

    @Published var examination: Examination = .init(
        _id: UUID().uuidString.lowercased(),
        goal: nil,
        preparationType: nil,
        slideId: "",
        recordVideo: nil,
        examinationDate: Date(),
        examinationPlanDate: Date(),
        statusExamination: .NOTSTARTED
    )

    @Published var examination2: Examination = .init(
        _id: UUID().uuidString.lowercased(),
        goal: nil,
        preparationType: nil,
        slideId: "",
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
                    let formattedDoB = patient.DoB.map { dateFormatter.string(from: $0) } ?? ""
                    patientNameDoB.append((patient.name + " (\(formattedDoB))", patient._id))
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
            name: "",
            NIK: "",
            DoB: Date(),
            sex: .UNKNOWN
        )
        selectedDoB = Date()
        selectedSex = ""
        BPJSnumber = ""
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
        print(patient.BPJS ?? "no data BPJS")
        print(patient.NIK)
        print(patient.DoB ?? "no data DoB")

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
        let examReq = ExaminationRequest(
            _id: examination._id,
            goal: examination.goal,
            preparationType: examination.preparationType,
            slideId: examination.slideId,
            examinationDate: examination.examinationDate,
            PIC: pic._id,
            DPJP: pic._id,
            examinationPlanDate: examination.examinationPlanDate
        )

        let examReq2 = ExaminationRequest(
            _id: examination2._id,
            goal: examination2.goal,
            preparationType: examination2.preparationType,
            slideId: examination2.slideId,
            examinationDate: examination2.examinationDate,
            PIC: pic._id,
            DPJP: pic._id,
            examinationPlanDate: examination2.examinationPlanDate
        )

        do {
            let response1 = try await interactor?.addNewExamination(patientId: patient._id, examination: examReq)
            let response2 = try await interactor?.addNewExamination(patientId: patient._id, examination: examReq2)

            if (response1 != nil) && (response2 != nil) {
                print("Examination added successfully")
                Router.shared.navigateTo(.home)
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
