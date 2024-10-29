//
//  HomePresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/10/24.
//

import Foundation

class HomePresenter: ObservableObject {
    var view: HomeView?
    var interactor: HomeInteractor? = HomeInteractor()

    @Published var statisticExam: ExaminationStatistic = .init()
    @Published var selectedLatestActivity: LatestActivityType = .semua
    @Published var latestExamination: [ExaminationCardData] = []
    @Published var filteredExamination: [ExaminationCardData] = []

    func getStatisticData() {
        interactor?.getStatisticExamination { result in
            switch result {
            case let .success(data):
                self.statisticExam = data
            case let .failure(error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func inputNewPatient() {
        interactor?.createNewPatient { result in
            switch result {
            case let .success(data):
                print("Patient ID: \(data._id)")
                print("Name: \(data.name)")
                print("NIK: \(data.NIK)")
                print("Date of Birth: \(data.DoB)")
                print("Sex: \(data.sex)")
                print("BPJS: \(String(describing: data.BPJS))")
                print("Result Examination: \(String(describing: data.resultExamination))")
            case let .failure(error):
                print("Error: ", error.localizedDescription)
            }
        }
    }

    func newInputRecord() {
        Router.shared.navigateTo(.newExam)
    }

    func filterLatestActivity(typeActivity: LatestActivityType) {
        selectedLatestActivity = typeActivity

        // Filter based on activity type
        switch typeActivity {
        case .semua:
            filteredExamination = latestExamination
        case .selesai:
            filteredExamination = latestExamination.filter { $0.statusExamination == .FINISHED }
        case .belumDisimpulkan:
            filteredExamination = latestExamination.filter { $0.statusExamination == .NEEDVALIDATION }
        }

        print("Pressed: ", typeActivity.rawValue)
    }

    func fetchData() {
        interactor?.getAllData { [weak self] result in
            switch result {
            case let .success(examinations):
                self?.latestExamination = examinations
                self?.filteredExamination = self?.latestExamination ?? []
            case let .failure(error):
                print("error: ", error.localizedDescription)
            }
        }
    }
}
