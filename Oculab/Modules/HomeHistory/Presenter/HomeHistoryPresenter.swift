//
//  HomeHistoryPresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/10/24.
//

import Foundation

class HomeHistoryPresenter: ObservableObject {
    var view: HomeView?
    var interactor: HomeInteractor? = HomeInteractor()

    @Published var selectedLatestActivity: LatestActivityType = .belumDimulai
    @Published var selectedDate: Date = .init()

    @Published var latestExamination: [ExaminationCardData] = []
    @Published var filteredExamination: [ExaminationCardData] = []
    @Published var filteredExaminationByDate: [ExaminationCardData] = []

    @Published var statisticExam: ExaminationStatistic = .init()

    @Published var isAllExamsLoading: Bool = false
    @Published var isStatisticLoading: Bool = false

    func getStatisticData() {
        isStatisticLoading = true
        interactor?.getStatisticExamination { [weak self] result in
            DispatchQueue.main.async {
                self?.isStatisticLoading = false
                switch result {
                case let .success(data):
                    self?.statisticExam = data
                case let .failure(error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }

    func filterLatestActivity(typeActivity: LatestActivityType) {
        selectedLatestActivity = typeActivity

        switch typeActivity {
        case .belumDimulai:
            filteredExamination = latestExamination.filter { $0.statusExamination == .NOTSTARTED }
        case .belumDisimpulkan:
            filteredExamination = latestExamination.filter { $0.statusExamination == .NEEDVALIDATION }
        }

        print("Pressed: ", typeActivity.rawValue)
    }

    func filterLatestActivityByDate(date: Date) {
        selectedDate = date

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        let selectedDateString = dateFormatter.string(from: selectedDate)

        filteredExaminationByDate = latestExamination
            .filter { $0.date == selectedDateString && $0.statusExamination == .FINISHED }
    }

    func fetchData() {
        isAllExamsLoading = true

        interactor?.getAllData { [weak self] result in
            DispatchQueue.main.async {
                self?.isAllExamsLoading = false
                switch result {
                case let .success(examinations):
                    self?.latestExamination = examinations
                    self?.filterLatestActivity(typeActivity: .belumDimulai)
                case let .failure(error):
                    print("error: ", error.localizedDescription)
                }
            }
        }
    }
}
