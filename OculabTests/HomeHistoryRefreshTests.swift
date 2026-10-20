import Combine
import XCTest
@testable import Oculab

final class HomeHistoryRefreshTests: XCTestCase {
    @MainActor
    private func withFixture(_ body: (HomeRefreshFixture) async throws -> Void) async throws {
        let keys: [KeychainKey] = [.accessToken, .refreshToken, .accessPin]
        let secrets = keys.map { ($0, KeychainHelper.string(for: $0)) }
        let defaults = UserDefaultType.allCases.map { ($0, UserDefaults.standard.object(forKey: $0.rawValue)) }
        let tracking = ["tracked_analysis_examination_ids", "pending_resume_analysis_examination_id"]
            .map { ($0, UserDefaults.standard.object(forKey: $0)) }
        let f = HomeRefreshFixture()
        defer {
            AuthSessionManager.beginSessionChange()
            for (key, value) in secrets {
                if let value { KeychainHelper.set(value, for: key) } else { KeychainHelper.remove(key) }
            }
            for (key, value) in defaults { UserDefaults.standard.set(value, forKey: key.rawValue) }
            for (key, value) in tracking { UserDefaults.standard.set(value, forKey: key) }
            AuthSessionManager.completeSessionChange()
            f.removeOwnedCacheFiles()
        }
        f.signIn()
        try await body(f)
    }

    @MainActor
    func testHomeRefreshKeepsRowsAndSearchWhileRequestIsPending() async throws {
        try await withFixture { f in
            await f.presenter.fetchData(userRole: .LAB)
            f.presenter.updateTaskSearchQuery("Rizky")
            let started = expectation(description: "Refresh held")
            let gate = HomeRefreshGate()
            f.network.response = { _ in
                started.fulfill()
                await gate.wait()
                return try HomeRefreshFixture.tasks(id: "updated")
            }
            let refresh = Task { await f.presenter.fetchData(userRole: .LAB) }
            await fulfillment(of: [started], timeout: 2)
            XCTAssertTrue(f.presenter.isAllExamsLoading)
            XCTAssertTrue(f.presenter.hasLoadedExaminations)
            XCTAssertEqual(f.presenter.filteredExamination.map(\.id), ["initial"])
            await gate.open()
            await refresh.value
            XCTAssertEqual(f.presenter.filteredExamination.map(\.id), ["updated"])
            XCTAssertEqual(f.presenter.taskSearchQuery, "Rizky")
            XCTAssertEqual(f.presenter.selectedLatestActivity, .belumDimulai)
            XCTAssertFalse(f.presenter.isAllExamsLoading)
        }
    }

    @MainActor
    func testFailedRefreshPreservesLoadedRowsAndLoadedEmptyState() async throws {
        for empty in [false, true] {
            try await withFixture { f in
                f.network.response = { _ in try empty ? HomeRefreshFixture.envelope([]) : HomeRefreshFixture.tasks(id: "initial") }
                await f.presenter.fetchData(userRole: .LAB)
                f.network.response = { _ in throw URLError(.networkConnectionLost) }
                await f.presenter.fetchData(userRole: .LAB)
                XCTAssertTrue(f.presenter.hasLoadedExaminations)
                XCTAssertEqual(f.presenter.latestExamination.map(\.id), empty ? [] : ["initial"])
                XCTAssertFalse(f.presenter.loadErrorMessage.isEmpty)
                XCTAssertFalse(f.presenter.isAllExamsLoading)
            }
        }
    }

    @MainActor
    func testInitialFailureIsAnErrorRatherThanSuccessfulEmptyList() async throws {
        try await withFixture { f in
            f.network.response = { _ in throw URLError(.notConnectedToInternet) }
            await f.presenter.fetchData(userRole: .LAB)
            XCTAssertFalse(f.presenter.hasLoadedExaminations)
            XCTAssertFalse(f.presenter.loadErrorMessage.isEmpty)
            XCTAssertTrue(f.presenter.latestExamination.isEmpty)
        }
    }

    @MainActor
    func testOlderHomeResponseCannotReplaceNewRowsOrCache() async throws {
        for fails in [false, true] {
            try await withFixture { f in
                let started = expectation(description: "Older request held")
                let gate = HomeRefreshGate()
                f.network.response = { _ in
                    started.fulfill()
                    await gate.wait()
                    if fails { throw URLError(.timedOut) }
                    return try HomeRefreshFixture.tasks(id: "old")
                }
                let old = Task { await f.presenter.fetchData(userRole: .LAB) }
                await fulfillment(of: [started], timeout: 2)
                f.network.response = { _ in try HomeRefreshFixture.tasks(id: "new") }
                await f.presenter.fetchData(userRole: .LAB)
                await gate.open()
                await old.value
                XCTAssertEqual(f.presenter.latestExamination.map(\.id), ["new"])
                XCTAssertTrue(f.presenter.loadErrorMessage.isEmpty)
                XCTAssertEqual(ExamListCacheService.shared.load(userId: f.owner, role: .LAB)?.examinations.map(\.id), ["new"])
            }
        }
    }

    @MainActor
    func testRapidDateChangesKeepLatestLoadingAndIgnoreOlderSuccessOrError() async throws {
        for fails in [false, true] {
            try await withFixture { f in
                let firstStarted = expectation(description: "First day held")
                let secondStarted = expectation(description: "Second day held")
                let firstGate = HomeRefreshGate()
                let secondGate = HomeRefreshGate()
                f.network.response = { _ in
                    firstStarted.fulfill()
                    await firstGate.wait()
                    if fails { throw URLError(.timedOut) }
                    return try HomeRefreshFixture.history(id: "wrong-day")
                }
                let first = Task { await f.presenter.fetchFinishedExaminationsByDate(date: f.day) }
                await fulfillment(of: [firstStarted], timeout: 2)
                f.network.response = { _ in
                    secondStarted.fulfill()
                    await secondGate.wait()
                    return try HomeRefreshFixture.history(id: "selected-day")
                }
                let second = Task { await f.presenter.fetchFinishedExaminationsByDate(date: f.nextDay) }
                await fulfillment(of: [secondStarted], timeout: 2)
                await firstGate.open()
                await first.value
                XCTAssertTrue(f.presenter.isAllExamsLoading, "The superseded request cannot stop the current spinner")
                XCTAssertTrue(f.presenter.finishedExaminationsByDate.isEmpty)
                XCTAssertTrue(f.presenter.loadErrorMessage.isEmpty)
                await secondGate.open()
                await second.value
                XCTAssertEqual(f.presenter.finishedExaminationsByDate.map(\.id), ["selected-day"])
                XCTAssertTrue(f.presenter.hasLoadedHistory)
            }
        }
    }

    @MainActor
    func testHistoryRefreshRetainsSameDayRowsOnFailureButNewDayDoesNotShowOldRows() async throws {
        try await withFixture { f in
            f.network.response = { _ in try HomeRefreshFixture.history(id: "first-day") }
            await f.presenter.fetchFinishedExaminationsByDate(date: f.day)
            f.network.response = { _ in throw URLError(.timedOut) }
            await f.presenter.fetchFinishedExaminationsByDate(date: f.day)
            XCTAssertEqual(f.presenter.finishedExaminationsByDate.map(\.id), ["first-day"])
            XCTAssertTrue(f.presenter.hasLoadedHistory)
            XCTAssertFalse(f.presenter.loadErrorMessage.isEmpty)
            await f.presenter.fetchFinishedExaminationsByDate(date: f.nextDay)
            XCTAssertTrue(f.presenter.finishedExaminationsByDate.isEmpty)
            XCTAssertFalse(f.presenter.hasLoadedHistory)
            XCTAssertFalse(f.presenter.loadErrorMessage.isEmpty)
        }
    }

    @MainActor
    func testFilterResetWinsAgainstDelayedAdvancedResults() async throws {
        try await withFixture { f in
            let started = expectation(description: "Filtered response held")
            let gate = HomeRefreshGate()
            f.network.response = { _ in
                started.fulfill()
                await gate.wait()
                return try HomeRefreshFixture.envelope(["items": [], "total": 0, "limit": 50, "offset": 0])
            }
            let filtered = Task { await f.presenter.applyHistoryFilters(.defaultRange(around: f.day)) }
            await fulfillment(of: [started], timeout: 2)
            f.network.response = { _ in try HomeRefreshFixture.history(id: "reset-day") }
            await f.presenter.resetHistoryFilters(around: f.nextDay)
            await gate.open()
            await filtered.value
            XCTAssertFalse(f.presenter.usesAdvancedHistoryFilters)
            XCTAssertEqual(f.presenter.finishedExaminationsByDate.map(\.id), ["reset-day"])
            XCTAssertTrue(f.presenter.loadErrorMessage.isEmpty)
        }
    }

    @MainActor
    func testSessionBoundaryClearsRowsAndRejectsLateListHistoryAndStatistics() async throws {
        for operation in 0..<3 {
            for logout in [false, true] {
                try await withFixture { f in
                    await f.presenter.fetchData(userRole: .LAB)
                    let started = expectation(description: "Response held across account boundary")
                    let gate = HomeRefreshGate()
                    f.network.response = { _ in
                        started.fulfill()
                        await gate.wait()
                        if operation == 0 { return try HomeRefreshFixture.tasks(id: "stale") }
                        if operation == 1 { return try HomeRefreshFixture.history(id: "stale") }
                        return try HomeRefreshFixture.envelope(["totalFinished": 99, "totalNotFinished": 1])
                    }
                    let pending = Task {
                        switch operation {
                        case 0: await f.presenter.fetchData(userRole: .LAB)
                        case 1: await f.presenter.fetchFinishedExaminationsByDate(date: f.day)
                        default: await f.presenter.getStatisticData()
                        }
                    }
                    await fulfillment(of: [started], timeout: 2)
                    if logout { AuthSessionManager.invalidateSession() } else { f.signIn(owner: f.secondOwner) }
                    await gate.open()
                    await pending.value
                    XCTAssertTrue(f.presenter.latestExamination.isEmpty)
                    XCTAssertTrue(f.presenter.finishedExaminationsByDate.isEmpty)
                    XCTAssertNil(f.presenter.statisticExam.totalFinished)
                    XCTAssertFalse(f.presenter.hasLoadedExaminations)
                    XCTAssertFalse(f.presenter.hasLoadedHistory)
                    XCTAssertFalse(f.presenter.isAllExamsLoading)
                    XCTAssertFalse(f.presenter.isStatisticLoading)
                    XCTAssertNil(ExamListCacheService.shared.load(userId: f.secondOwner, role: .LAB))
                }
            }
        }
    }

    @MainActor
    func testSlowStatisticsDoNotDelayTaskList() async throws {
        try await withFixture { f in
            let statisticsStarted = expectation(description: "Statistics held")
            let tasksStarted = expectation(description: "Tasks requested without waiting for statistics")
            let gate = HomeRefreshGate()
            let rowsLoaded = expectation(description: "Task rows visible while statistics are pending")
            let observer = f.presenter.$hasLoadedExaminations.filter { $0 }.prefix(1).sink { _ in rowsLoaded.fulfill() }
            f.network.response = { path in
                if path.contains("statistics") {
                    statisticsStarted.fulfill()
                    await gate.wait()
                    return try HomeRefreshFixture.envelope(["totalFinished": 1, "totalNotFinished": 5])
                }
                tasksStarted.fulfill()
                return try HomeRefreshFixture.tasks(id: "ready")
            }
            let refresh = Task { await f.presenter.refreshHome(userRole: .LAB) }
            await fulfillment(of: [statisticsStarted, tasksStarted, rowsLoaded], timeout: 2)
            XCTAssertTrue(f.presenter.hasLoadedExaminations)
            XCTAssertEqual(f.presenter.latestExamination.map(\.id), ["ready"])
            XCTAssertTrue(f.presenter.isStatisticLoading)
            await gate.open()
            await refresh.value
            XCTAssertEqual(f.presenter.statisticExam.totalFinished, 1)
            XCTAssertEqual(f.presenter.progress, 1.0 / 6.0, accuracy: 0.001)
            withExtendedLifetime(observer) {}
        }
    }

    @MainActor
    func testAdminStartsOnAvailableFilterWithoutOverridingExplicitSelection() async throws {
        try await withFixture { f in
            f.network.response = { _ in try HomeRefreshFixture.envelope([]) }
            await f.presenter.fetchData(userRole: .ADMIN)
            XCTAssertEqual(f.presenter.selectedLatestActivity, .semua)
            f.presenter.resetState()
            await f.presenter.filterLatestActivity(typeActivity: .butuhVerifikasi)
            await f.presenter.fetchData(userRole: .ADMIN)
            XCTAssertEqual(f.presenter.selectedLatestActivity, .butuhVerifikasi)
        }
    }

    @MainActor
    func testCancelledRequestDoesNotPublishErrorOrReplaceResults() async throws {
        try await withFixture { f in
            let started = expectation(description: "Cancelled history request held")
            let gate = HomeRefreshGate()
            f.network.response = { _ in
                started.fulfill()
                await gate.wait()
                return try HomeRefreshFixture.history(id: "cancelled")
            }
            let pending = Task { await f.presenter.fetchFinishedExaminationsByDate(date: f.day) }
            await fulfillment(of: [started], timeout: 2)
            pending.cancel()
            await gate.open()
            await pending.value
            XCTAssertTrue(f.presenter.finishedExaminationsByDate.isEmpty)
            XCTAssertFalse(f.presenter.hasLoadedHistory)
            XCTAssertTrue(f.presenter.loadErrorMessage.isEmpty)
            XCTAssertFalse(f.presenter.isAllExamsLoading)
        }
    }
}

@MainActor
private final class HomeRefreshFixture {
    let owner = "home-review-" + UUID().uuidString.lowercased()
    let secondOwner = "home-review-" + UUID().uuidString.lowercased()
    let network = HomeRefreshNetwork()
    lazy var presenter = HomeHistoryPresenter(
        interactor: HomeInteractor(networkService: network),
        networkRetryManager: NetworkRetryManager(monitorsConnectivity: false)
    )
    let day = Date(timeIntervalSince1970: 1_780_704_000)
    var nextDay: Date { Calendar.current.date(byAdding: .day, value: 1, to: day)! }

    func signIn(owner: String? = nil) {
        let owner = owner ?? self.owner
        AuthSessionManager.beginSessionChange()
        UserDefaults.standard.set(true, forKey: UserDefaultType.isUserLoggedIn.rawValue)
        UserDefaults.standard.set(owner, forKey: UserDefaultType.userId.rawValue)
        KeychainHelper.set("fixture-token", for: .accessToken)
        AuthSessionManager.completeSessionChange()
    }

    func removeOwnedCacheFiles() {
        guard let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        for id in [owner, secondOwner] {
            for role in [RolesType.LAB, .ADMIN] {
                let file = support.appendingPathComponent("ExamListCache/\(id)_\(role.rawValue).json")
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    static func envelope(_ data: Any) throws -> Data {
        try JSONSerialization.data(withJSONObject: ["status": "success", "code": 200, "message": "OK", "data": data])
    }
    static func tasks(id: String) throws -> Data {
        try envelope([["id": id, "slideId": "slide-1", "statusExamination": "NOTSTARTED", "patientId": "fixture-patient", "patientName": "Rizky", "patientDob": "2000-01-01"]])
    }
    static func history(id: String) throws -> Data {
        try envelope([["examinationId": id, "patientId": "fixture-patient", "slideId": "slide-1", "patientName": "Rizky", "patientDob": "2000-01-01", "finalGradingResult": GradingType.unknown.rawValue]])
    }
}

private final class HomeRefreshNetwork: MockNetworkService {
    var response: @MainActor (String) async throws -> Data = { _ in try HomeRefreshFixture.tasks(id: "initial") }
    override func get<T: Decodable>(urlString: String, headers: [String: String]?) async throws -> APIResponse<T> {
        let payload = try await response(urlString)
        return try JSONDecoder().decode(APIResponse<T>.self, from: payload)
    }
}

private actor HomeRefreshGate {
    private var continuations: [CheckedContinuation<Void, Never>] = []
    private var isOpen = false
    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { continuations.append($0) }
    }
    func open() {
        isOpen = true
        continuations.forEach { $0.resume() }
        continuations.removeAll()
    }
}
