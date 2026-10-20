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
    private let cacheService: ExamListCacheService
    private let networkRetryManager: NetworkRetryManager
    private var listRequestID: UUID?
    private var historyRequestID: UUID?
    private var statisticsRequestID: UUID?
    private var loadedHistoryQuery: HistoryQuery?
    private var sessionObserver: NSObjectProtocol?

    private enum HistoryQuery: Equatable {
        case day(String)
        case filters(HistoryExamFilters)
    }

    init(
        interactor: HomeInteractor = HomeInteractor(),
        cacheService: ExamListCacheService = .shared,
        networkRetryManager: NetworkRetryManager = DependencyInjection.shared.networkRetryManager
    ) {
        self.interactor = interactor
        self.cacheService = cacheService
        self.networkRetryManager = networkRetryManager
        sessionObserver = NotificationCenter.default.addObserver(
            forName: AuthSessionManager.sessionDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.resetState() }
        }
    }

    deinit {
        if let sessionObserver { NotificationCenter.default.removeObserver(sessionObserver) }
    }

    // MARK: - Published Properties
    @Published var selectedLatestActivity: LatestActivityType = .belumDimulai
    @Published var selectedDate: Date = .init()
    @Published var taskSearchQuery: String = ""

    @Published var latestExamination: [ExaminationCardData] = []
    @Published var filteredExamination: [ExaminationCardData] = []
    @Published var filteredExaminationByDate: [ExaminationCardData] = []
    
    @Published var finishedExaminationsByDate: [FinishedExaminationCardData] = []
    @Published var unfinishedExaminationsByDate: [FinishedExaminationCardData] = []

    @Published var statisticExam: ExaminationStatistic = .init()
    @Published var progress: CGFloat = 0.0

    @Published var isAllExamsLoading: Bool = false
    @Published var isStatisticLoading: Bool = false
    @Published private(set) var hasLoadedExaminations = false
    @Published private(set) var hasLoadedHistory = false
    @Published var loadErrorMessage: String = ""
    @Published var isShowingCachedData: Bool = false
    @Published var cachedAt: Date?
    @Published var historyFilters: HistoryExamFilters = .defaultRange()
    @Published var usesAdvancedHistoryFilters: Bool = false
    
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
    func refreshHome(userRole: RolesType) async {
        async let statistics: Void = getStatisticData()
        async let examinations: Void = fetchData(userRole: userRole)
        _ = await (statistics, examinations)
    }

    @MainActor
    func getStatisticData() async {
        guard let session = AuthSessionManager.uploadQueueSession else { return }
        let requestID = UUID()
        statisticsRequestID = requestID
        isStatisticLoading = true
        defer {
            if statisticsRequestID == requestID { isStatisticLoading = false }
        }
        do {
            let response = try await interactor.getStatisticExamination()
            guard !Task.isCancelled, statisticsRequestID == requestID,
                  session == AuthSessionManager.uploadQueueSession else { return }
            statisticExam = response
            calculateProgress()
        } catch {
            guard !Task.isCancelled, statisticsRequestID == requestID,
                  session == AuthSessionManager.uploadQueueSession else { return }
            Logger.error("Failed to fetch statistics: \(error.localizedDescription)", category: .general)
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
        applyTaskFilters()
    }

    @MainActor
    func updateTaskSearchQuery(_ query: String) {
        taskSearchQuery = query
        applyTaskFilters()
    }
    
    var hasAnyExaminations: Bool {
        !latestExamination.isEmpty
    }

    func examinationCount(for type: LatestActivityType) -> Int {
        // Chip counts stay status-only so searching doesn't shrink the chips.
        statusFilteredExaminations(by: type).count
    }

    private func applyTaskFilters() {
        filteredExamination = getFilteredExaminations(by: selectedLatestActivity)
    }

    private func statusFilteredExaminations(by type: LatestActivityType) -> [ExaminationCardData] {
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

    private func getFilteredExaminations(by type: LatestActivityType) -> [ExaminationCardData] {
        let byStatus = statusFilteredExaminations(by: type)

        let query = taskSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return byStatus }

        let needle = query.lowercased()
        return byStatus.filter { exam in
            exam.slideId.lowercased().contains(needle)
                || exam.patientName.lowercased().contains(needle)
                || exam.picName.lowercased().contains(needle)
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
        if usesAdvancedHistoryFilters {
            await fetchFilteredExaminations()
        } else {
            await fetchHistory(query: .day(date.formattedYearMonthDay()))
        }
    }

    @MainActor
    func fetchFilteredExaminations() async {
        await fetchHistory(query: .filters(historyFilters))
    }

    @MainActor
    private func fetchHistory(query: HistoryQuery) async {
        guard let session = AuthSessionManager.uploadQueueSession else { return }
        let requestID = UUID()
        historyRequestID = requestID
        // Keep rows for a refresh, but never show a different date's results
        // beneath the newly selected date or filters.
        if loadedHistoryQuery != query {
            finishedExaminationsByDate = []
            hasLoadedHistory = false
        }
        isAllExamsLoading = true
        loadErrorMessage = ""
        defer {
            if historyRequestID == requestID { isAllExamsLoading = false }
        }
        do {
            let response: [FinishedExaminationCardData]
            switch query {
            case .day(let date): response = try await interactor.getFinishedDataCard(date: date)
            case .filters(let filters): response = try await interactor.getFacilityExaminations(filters: filters)
            }
            guard !Task.isCancelled, historyRequestID == requestID,
                  session == AuthSessionManager.uploadQueueSession else { return }
            finishedExaminationsByDate = response
            loadedHistoryQuery = query
            hasLoadedHistory = true
        } catch {
            guard !Task.isCancelled, historyRequestID == requestID,
                  session == AuthSessionManager.uploadQueueSession else { return }
            loadErrorMessage = ErrorHandler.shared.handleError(error)
        }
    }

    @MainActor
    func applyHistoryFilters(_ filters: HistoryExamFilters) async {
        historyFilters = filters
        usesAdvancedHistoryFilters = true
        await fetchFilteredExaminations()
    }

    @MainActor
    func resetHistoryFilters(around date: Date) async {
        historyFilters = .defaultRange(around: date)
        usesAdvancedHistoryFilters = false
        await fetchFinishedExaminationsByDate(date: date)
    }
    
    @MainActor
    func fetchData(userRole: RolesType) async {
        guard let session = AuthSessionManager.uploadQueueSession else { return }
        let requestID = UUID()
        listRequestID = requestID
        if !hasLoadedExaminations, userRole == .ADMIN, selectedLatestActivity == .belumDimulai {
            selectedLatestActivity = .semua
        }
        isAllExamsLoading = true
        loadErrorMessage = ""
        if !hasLoadedExaminations { _ = tryLoadCachedExamList(for: userRole) }
        defer {
            if listRequestID == requestID { isAllExamsLoading = false }
        }
        do {
            let response = try await getExaminationData(for: userRole)
            guard !Task.isCancelled, listRequestID == requestID,
                  session == AuthSessionManager.uploadQueueSession else { return }
            latestExamination = response
            loadErrorMessage = ""
            isShowingCachedData = false
            cachedAt = nil
            hasLoadedExaminations = true
            cacheService.save(examinations: response, userId: session.ownerUserId, role: userRole)
            applyTaskFilters()
        } catch {
            guard !Task.isCancelled, listRequestID == requestID,
                  session == AuthSessionManager.uploadQueueSession else { return }
            if !tryLoadCachedExamList(for: userRole) {
                // A failed background refresh must not erase usable rows or
                // reset the search/status selection the user is working with.
                loadErrorMessage = ErrorHandler.shared.handleError(error)
            }
        }
    }

    @MainActor
    @discardableResult
    private func tryLoadCachedExamList(for userRole: RolesType) -> Bool {
        guard !networkRetryManager.isConnected,
              let userId = currentUserId(),
              let cached = cacheService.load(userId: userId, role: userRole),
              cached.userId == userId
        else { return false }

        latestExamination = cached.examinations
        hasLoadedExaminations = true
        isShowingCachedData = true
        cachedAt = cached.cachedAt
        loadErrorMessage = ""
        applyTaskFilters()
        return true
    }

    private func currentUserId() -> String? {
        UserDefaults.standard.string(forKey: UserDefaultType.userId.rawValue)
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
        listRequestID = nil
        historyRequestID = nil
        statisticsRequestID = nil
        loadedHistoryQuery = nil
        hasLoadedExaminations = false
        hasLoadedHistory = false
        loadErrorMessage = ""
        usesAdvancedHistoryFilters = false
        historyFilters = .defaultRange()
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
        taskSearchQuery = ""
        isShowingCachedData = false
        cachedAt = nil
    }
}
