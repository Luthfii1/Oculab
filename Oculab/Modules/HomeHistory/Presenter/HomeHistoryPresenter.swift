//
//  HomeHistoryPresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/10/24.
//

import Foundation

class HomeHistoryPresenter: ObservableObject {
    // MARK: - Dependencies
    var view: HomeView?
    private let interactor: HomeInteractor

    init(interactor: HomeInteractor = HomeInteractor()) {
        self.interactor = interactor
    }

    // MARK: - Published Properties
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
    
    // MARK: - Constants
    private struct Constants {
        static let dateDisplayFormat = "dd MMMM yyyy"
        static let localeIdentifier = "en_US_POSIX"
        static let maxProgress: CGFloat = 1.0
        static let minProgress: CGFloat = 0.0
    }
}

// MARK: - Statistics Methods
extension HomeHistoryPresenter {
    @MainActor
    func getStatisticData() async {
        isStatisticLoading = true
        defer { isStatisticLoading = false }

        do {
            statisticExam = try await interactor.getStatisticExamination()
            calculateProgress()
        } catch {
            Logger.error("Failed to fetch statistics: \(error.localizedDescription)", category: .general)
            _ = ErrorHandler.shared.handleError(error)
        }
    }
    
    private func calculateProgress() {
        guard let totalFinished = statisticExam.totalFinished,
              let totalNotFinished = statisticExam.totalNotFinished else {
            progress = Constants.minProgress
            return
        }
        
        let totalExaminations = totalFinished + totalNotFinished
        
        if totalExaminations > 0 {
            progress = CGFloat(Double(totalFinished) / Double(totalExaminations))
        } else if totalFinished > 0 && totalNotFinished == 0 {
            progress = Constants.maxProgress
        } else {
            progress = Constants.minProgress
        }
    }
}

// MARK: - Filtering Methods
extension HomeHistoryPresenter {
    @MainActor
    func filterLatestActivity(typeActivity: LatestActivityType) async {
        selectedLatestActivity = typeActivity
        filteredExamination = getFilteredExaminations(by: typeActivity)
    }
    
    private func getFilteredExaminations(by type: LatestActivityType) -> [ExaminationCardData] {
        switch type {
        case .semua:
            return latestExamination
        case .butuhVerifikasi:
            return latestExamination.filter { $0.statusExamination == .NEEDVALIDATION }
        case .belumDimulai:
            return latestExamination.filter { $0.statusExamination == .NOTSTARTED }
        case .belumDisimpulkan:
            return latestExamination.filter { 
                $0.statusExamination == .NEEDVALIDATION || $0.statusExamination == .INPROGRESS 
            }
        }
    }

    func filterLatestActivityByDate(date: Date) {
        selectedDate = date
        let selectedDateString = formatDateForDisplay(date)
        
        filteredExaminationByDate = latestExamination.filter { 
            $0.date == selectedDateString && $0.statusExamination == .FINISHED 
        }
    }
    
    private func formatDateForDisplay(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.dateDisplayFormat
        dateFormatter.locale = Locale(identifier: Constants.localeIdentifier)
        return dateFormatter.string(from: date)
    }
}

// MARK: - Data Fetching Methods
extension HomeHistoryPresenter {
    @MainActor
    func fetchFinishedExaminationsByDate(date: Date) async {
        let dateString = date.formattedYearMonthDay()
        
        isAllExamsLoading = true
        finishedExaminationsByDate.removeAll()
        
        defer { isAllExamsLoading = false }
        
        do {
            let response = try await interactor.getFinishedDataCard(date: dateString)
            
            handleFinishedExaminationsResponse(response, for: dateString)
            
        } catch {
            finishedExaminationsByDate = []
            Logger.error("Failed to fetch examinations for date \(dateString): \(error.localizedDescription)", category: .general)
            _ = ErrorHandler.shared.handleError(error)
        }
    }
    
    private func handleFinishedExaminationsResponse(_ response: [FinishedExaminationCardData], for dateString: String) {
        finishedExaminationsByDate = response
        Logger.info("Loaded \(response.count) examinations", category: .general)
    }
    
    @MainActor
    func fetchData(userRole: RolesType) async {
        isAllExamsLoading = true
        defer { isAllExamsLoading = false }

        do {
            latestExamination = try await getExaminationData(for: userRole)
            await filterLatestActivity(typeActivity: selectedLatestActivity)
        } catch {
            Logger.error("Failed to fetch examination data for role \(userRole): \(error.localizedDescription)", category: .general)
            _ = ErrorHandler.shared.handleError(error)
        }
    }
    
    private func getExaminationData(for userRole: RolesType) async throws -> [ExaminationCardData] {
        if userRole == .ADMIN {
            return try await interactor.getAllDataAdmin()
        } else {
            return try await interactor.getAllData()
        }
    }
}

// MARK: - State Management
extension HomeHistoryPresenter {
    @MainActor
    func resetState() {
        latestExamination = []
        filteredExamination = []
        filteredExaminationByDate = []
        finishedExaminationsByDate = []
        unfinishedExaminationsByDate = []
        statisticExam = .init()
        progress = 0.0
        isAllExamsLoading = false
        isStatisticLoading = false
        selectedLatestActivity = .belumDimulai
    }
}
