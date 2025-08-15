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
    @Published var unfinishedExaminationsByDate: [FinishedExaminationCardData] = []

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

            // Calculate progress only for Lab users (when totalFinished and totalNotFinished are available)
            if statisticExam.totalFinished != nil && statisticExam.totalNotFinished != nil {
                let totalFinished = statisticExam.totalFinished ?? 0
                let totalNotFinished = statisticExam.totalNotFinished ?? 0
                
                if totalFinished + totalNotFinished > 0 {
                    progress = CGFloat(
                        Double(totalFinished) / Double(totalFinished + totalNotFinished)
                    )
                } else if totalFinished != 0 && totalNotFinished == 0 {
                    progress = 1.0
                } else {
                    progress = 0.0
                }
            }
            
        } catch {
            _ = ErrorHandler.shared.handleError(error)
        }
    }

    @MainActor
    func filterLatestActivity(typeActivity: LatestActivityType) async {
        selectedLatestActivity = typeActivity

        switch typeActivity {
            case .semua:
                filteredExamination = latestExamination
            case .butuhVerifikasi:
                filteredExamination = latestExamination.filter { $0.statusExamination == .NEEDVALIDATION }
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
        let dateString = date.formattedYearMonthDay()
        
        isAllExamsLoading = true
        finishedExaminationsByDate.removeAll()
        
        defer {
            isAllExamsLoading = false
        }
        
        do {
            let response = try await interactor?.getFinishedDataCard(date: dateString)
            
            if let response = response, !response.isEmpty {
                finishedExaminationsByDate = response
                print("📊 Successfully loaded \(response.count) examinations for date: \(dateString)")
            } else {
                finishedExaminationsByDate = []
                print("📭 No examinations found for date: \(dateString)")
            }
            
        } catch {
            finishedExaminationsByDate = []
            
            _ = ErrorHandler.shared.handleError(error)
        }
    }
    
    @MainActor
    func fetchData(userRole: RolesType) async {
        isAllExamsLoading = true
        defer { isAllExamsLoading = false }

        do {
            let response: [ExaminationCardData]?
            
            if userRole == .ADMIN {
                response = try await interactor?.getAllDataAdmin()
            } else {
                response = try await interactor?.getAllData()
            }

            if let response {
                latestExamination = response
                await filterLatestActivity(typeActivity: selectedLatestActivity)
            }
        } catch {
            _ = ErrorHandler.shared.handleError(error)
        }
    }
}
