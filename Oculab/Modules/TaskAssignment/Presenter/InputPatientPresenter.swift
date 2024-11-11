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

    var goalString2: String {
        get { examination.goal?.rawValue ?? "" }
        set { examination.goal = ExamGoalType(rawValue: newValue) }
    }

    var typeString: String {
        get { examination.preparationType?.rawValue ?? "" }
        set { examination.preparationType = ExamPreparationType(rawValue: newValue) }
    }

    var typeString2: String {
        get { examination.preparationType?.rawValue ?? "" }
        set { examination.preparationType = ExamPreparationType(rawValue: newValue) }
    }

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
        Router.shared.navigateTo(.newExam(patientId: patient._id, picId: pic._id))
    }

    func addNewPatient() {
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

            case let .failure(error):
                print(error)
                print("Add new patient")
            }
        }
    }

    func submitExamination() {
        print(examination._id)
        print(examination.goal)
        print(examination.slideId)
        print(examination.preparationType)
        print(examination.examinationDate)
        print(examination.picId)
        print(examination.dpjpId)
        print(examination.examinationPlanDate)
        examination.picId = examination.PIC?._id
        examination.dpjpId = examination.DPJP?._id

        print(examination2._id)
        print(examination2.goal)
        print(examination2.slideId)
        print(examination2.preparationType)
        print(examination2.examinationDate)
        print(examination2.picId)
        print(examination2.dpjpId)
        print(examination2.examinationPlanDate)
        examination2.picId = examination2.PIC?._id
        examination2.dpjpId = examination2.DPJP?._id

//        {
//            "_id": "b55d127d-ab82-378a-fb6e-acb378ab137d",
//            "goal": "SCREENING",
//            "preparationType": "SP",
//            "slideId": "24/12/2/0129A",
//            "examinationDate": "2024-11-12T13:51:17.951Z",
//            "PIC": "b38968af-8ede-4d55-958d-7f9944c46c92",
//            "DPJP": "34626c19-1a72-402b-9ec1-5a927d0d2cef",
//            "examinationPlanDate": "2024-11-02T13:51:17.951Z"
//        }

        interactor?.addNewExamination(patientId: patient._id, examination: examination) { [weak self] result in
            switch result {
            case let .success(data):
                print(data)

            case let .failure(error):
                print(error)
                print(result)
            }
        }

        interactor?.addNewExamination(patientId: patient._id, examination: examination2) { [weak self] result in
            switch result {
            case let .success(data):
//                self?.examination2 = data
                print(data)

            case let .failure(error):
                print(error)
                print(result)
            }
        }
    }
}
