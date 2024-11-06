//
//  SharedPresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/10/24.
//

import Foundation

class SharedPresenter: ObservableObject {
    var view: HomeView?
    var interactor: HomeInteractor? = HomeInteractor()

    @Published var selectedLatestActivity: LatestActivityType = .belumDimulai
    @Published var selectedDate: Date = .init()

    @Published var latestExamination: [ExaminationCardData] = []
    @Published var filteredExamination: [ExaminationCardData] = []
    @Published var filteredExaminationByDate: [ExaminationCardData] = []

    func filterLatestActivity(typeActivity: LatestActivityType) {
        selectedLatestActivity = typeActivity

        // Filter based on activity type
        switch typeActivity {
        case .belumDimulai:
            filteredExamination = latestExamination.filter { $0.statusExamination == .NOTSTARTED }
        case .belumDisimpulkan:
            filteredExamination = latestExamination.filter { $0.statusExamination == .INPROGRESS }
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
        print("masuk")
        interactor?.getAllData { [weak self] result in
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
