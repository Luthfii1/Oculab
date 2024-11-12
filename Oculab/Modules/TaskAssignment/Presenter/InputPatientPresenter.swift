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

    @Published var patientFound: Bool = false

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

    func getAllUser() {
        isUserLoading = true
        interactor?.getAllUser { [weak self] result in
            DispatchQueue.main.async {
                self?.isUserLoading = false
                switch result {
                case let .success(data):
                    for pic in data {
                        self?.picName.append((pic.name, pic._id))
                    }
                case let .failure(error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }

    func getAllPatient() {
        isPatientLoading = true
        interactor?.getAllPatient { [weak self] result in
            DispatchQueue.main.async {
                self?.isPatientLoading = false
                switch result {
                case let .success(data):
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd/MM/yyyy"

                    for patient in data {
                        let formattedDoB = patient.DoB.map { dateFormatter.string(from: $0) } ?? ""
                        self?.patientNameDoB.append((patient.name + " (\(formattedDoB))", patient._id))
                    }
                case let .failure(error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }

    func getPatientById(patientId: String) {
        isPatientLoading = true

        interactor?.getPatientById(patientId: patientId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isPatientLoading = false

                switch result {
                case let .success(data):
                    self?.patient = data
                    self?.patientFound = true

                case let .failure(error):
                    self?.patient = .init(
                        _id: UUID().uuidString.lowercased(),
                        name: "",
                        NIK: "",
                        DoB: Date(),
                        sex: .MALE
                    )
                    self?.patientFound = false
                }
            }
        }
    }

    func getUserById(userId: String) {
        isUserLoading = true

        interactor?.getUserById(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isUserLoading = false

                switch result {
                case let .success(data):
                    print("{}{}{}{}")
                    print(data.name)
                    self?.pic = data

                case let .failure(error):
                    print(error)
                }
            }
        }
    }

    func newExam() {
        if !patientFound {
            addNewPatient { [weak self] success in
                if success {
                    self?.navigateToNewExam()
                } else {
                    print("Failed to add new patient.")
                }
            }
        } else {
            navigateToNewExam()
        }
    }

    func addNewPatient(completion: @escaping (Bool) -> Void) {
        print(patient._id)
        print(patient.name)
        print(patient.BPJS)
        print(patient.NIK)
        print(patient.DoB)

        interactor?.addNewPatient(patient: patient) { [weak self] result in
            switch result {
            case let .success(data):
                self?.patient = data
                print(data)
                completion(true) // Indicate success to the caller

            case let .failure(error):
                print(error)
                print("Add new patient")
                completion(false) // Indicate failure to the caller
            }
        }
    }

    private func navigateToNewExam() {
        Router.shared.navigateTo(.newExam(patientId: patient._id, picId: pic._id))
    }

    func submitExamination() {
        var examReq = ExaminationRequest(
            _id: examination._id,
            goal: examination.goal,
            preparationType: examination.preparationType,
            slideId: examination.slideId,
            examinationDate: examination.examinationDate,
            PIC: pic._id,
            DPJP: pic._id,
            examinationPlanDate: examination.examinationPlanDate
        )

        var examReq2 = ExaminationRequest(
            _id: examination2._id,
            goal: examination2.goal,
            preparationType: examination2.preparationType,
            slideId: examination2.slideId,
            examinationDate: examination2.examinationDate,
            PIC: pic._id,
            DPJP: pic._id,
            examinationPlanDate: examination2.examinationPlanDate
        )

        interactor?.addNewExamination(
            patientId: patient._id,
            examination: examReq
        ) { [weak self] result in
            switch result {
            case let .success(data):
                print(data)

            case let .failure(error):
                print(error)
            }
        }

        interactor?.addNewExamination(patientId: patient._id, examination: examReq2) { [weak self] result in
            switch result {
            case let .success(data):
                print(data)

            case let .failure(error):
                print(error)
            }
        }

        Router.shared.navigateTo(.home)
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
