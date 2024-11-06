//
//  HomePresenter.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 06/11/24.
//

import Foundation

class HomePresenter: ObservableObject {
    var interactor: HomeInteractor? = HomeInteractor()

    @Published var statisticExam: ExaminationStatistic = .init()

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
}
