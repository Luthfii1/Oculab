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

    @Published var positifCount: Int = 0
    @Published var negatifCount: Int = 0
    @Published var selectedLatestActivity: LatestActivityType = .semua
    @Published var latestExamination: [ExaminationCardData] = []
    @Published var filteredExamination: [ExaminationCardData] = []

    func getStatisticData() {
        positifCount = 5
        negatifCount = 2
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
            filteredExamination = latestExamination.filter { $0.statusExamination == .done }
        case .belumDisimpulkan:
            filteredExamination = latestExamination.filter { $0.statusExamination == .draft }
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
                print("error")
            }
        }
    }
}
