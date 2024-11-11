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

    @Published var patient: Patient = .init(_id: "", name: "", NIK: "", DoB: Date(), sex: .UNKNOWN)
    @Published var pic: User = .init(_id: "", name: "", role: .ADMIN)

    @Published var examination: Examination = .init(
        _id: "",
        goal: nil,
        preparationType: nil,
        slideId: "",
        recordVideo: nil,
        examinationDate: Date(),
        examinationPlanDate: Date(),
        statusExamination: .NOTSTARTED
    )

    @Published var examination2: Examination = .init(
        _id: "",
        goal: nil,
        preparationType: nil,
        slideId: "",
        recordVideo: nil,
        examinationDate: Date(),
        examinationPlanDate: Date(),
        statusExamination: .NOTSTARTED
    )

    var goalString: String {
        get { examination.goal?.rawValue ?? "" }
        set { examination.goal = ExamGoalType(rawValue: newValue) }
    }

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

                case let .failure(error):
                    self?.patient = .init(_id: "", name: "", NIK: "", DoB: Date(), sex: .MALE)
                    print("Add new patient")
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
        addNewPatient()

        Router.shared.navigateTo(.newExam(patientId: patient._id, picId: pic._id))
    }

    func addNewPatient() {
        print("MASUK SIH")
        interactor?.addNewPatient(patient: patient) { [weak self] _ in
            print("AAAAAAAAAAAAA")
        }
    }
}
