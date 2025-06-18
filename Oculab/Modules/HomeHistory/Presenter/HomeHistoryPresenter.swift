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
    
    @Published var finishedExaminationsByDate: [FinishedExaminationCardData] = []

    @Published var statisticExam: ExaminationStatistic = .init()
    @Published var progress: CGFloat = 0.0

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

            if statisticExam.totalFinished + statisticExam.totalNotFinished > 0 {
                progress = CGFloat(
                    Double(statisticExam.totalFinished) /
                        Double(statisticExam.totalFinished + statisticExam.totalNotFinished)
                )

            } else if statisticExam.totalFinished != 0 && statisticExam.totalNotFinished == 0 {
                progress = 1.0
            }
        } catch {
            // Handle error
            switch error {
            case let NetworkError.apiError(apiResponse):
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")

            case let NetworkError.networkError(message):
                print("Network error getStatisticData: \(message)")

            default:
                print("Unknown error: \(error.localizedDescription)")
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
            filteredExamination = latestExamination
                .filter { $0.statusExamination == .NEEDVALIDATION || $0.statusExamination == .INPROGRESS }
        }
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
    func fetchFinishedExaminationsByDate(date: Date) async {
        isAllExamsLoading = true
        defer { isAllExamsLoading = false }
        
        do {
            let response = try await interactor?.getFinishedDataCard(date: date.formattedYearMonthDay())
            
            if let response {
                finishedExaminationsByDate = response
                print("Successfully loaded \(response.count) examinations")
            } else {
                finishedExaminationsByDate = []
                print("No response from interactor")
            }
            
        } catch {
            // Handle different types of errors
            switch error {
                case let NetworkError.apiError(apiResponse):
                    if apiResponse.data.errorType == "VALIDATION_ERROR" &&
                       apiResponse.data.description.contains("No finished examinations found") {
                        finishedExaminationsByDate = []
                    }
                    
                case let NetworkError.networkError(message):
                    print("Network error: \(message)")
                    
                default:
                    print("Unknown error: \(error.localizedDescription)")
                }
        }
    }
    
    @MainActor
    func fetchData() async {
        isAllExamsLoading = true
        defer { isAllExamsLoading = false }

        do {
            let response = try await interactor?.getAllData()

            if let response {
                latestExamination = response
                await filterLatestActivity(typeActivity: selectedLatestActivity)
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
