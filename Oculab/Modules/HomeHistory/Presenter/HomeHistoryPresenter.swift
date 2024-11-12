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

    @MainActor
    func getStatisticData() async {
        isStatisticLoading = true
        defer { isStatisticLoading = false }

        do {
            let data = try await interactor?.getStatisticExamination()

            if let data {
                statisticExam = data
            }
        } catch {
            // Handle error
            if let apiError = error as? APIResponse<ApiErrorData> {
                print("Error description: \(apiError.data.description)")
                print("Error type: \(apiError.data.errorType)")
            } else {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func filterLatestActivity(typeActivity: LatestActivityType) async {
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

    @MainActor
    func fetchData() async {
        isAllExamsLoading = true
        defer { isAllExamsLoading = false }

        do {
            let response = try await interactor?.getAllData()

            if let response {
                latestExamination = response
                await filterLatestActivity(typeActivity: .belumDimulai)
            }
        } catch {
            // Handle error
            if let apiError = error as? APIResponse<ApiErrorData> {
                print("Error description: \(apiError.data.description)")
                print("Error type: \(apiError.data.errorType)")
            } else {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}
