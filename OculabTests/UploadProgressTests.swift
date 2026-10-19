@testable import Oculab
import SwiftData
import SwiftUI
import UIKit
import XCTest

final class UploadProgressTests: XCTestCase {
    @MainActor
    private func fixture(state: PendingUploadState) throws -> (VideoUploadQueueService, ModelContext, PendingUpload) {
        let schema = Schema([PendingUpload.self])
        let container = try ModelContainer(for: schema, configurations: [
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        ])
        let context = ModelContext(container)
        let session = UploadQueueSession(ownerUserId: "upload-progress-owner", generation: UUID())
        let queue = VideoUploadQueueService(sessionProvider: { session })
        let network = NetworkRetryManager(monitorsConnectivity: false)
        network.isConnected = false
        queue.configure(modelContext: context, examInteractor: ExamInteractor(networkService: MockNetworkService()), networkRetryManager: network)
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
        try Data("saved-video".utf8).write(to: file)
        addTeardownBlock { try? FileManager.default.removeItem(at: file) }
        let upload = PendingUpload(
            examinationId: UUID().uuidString.lowercased(), patientId: "patient",
            localFilePath: file.path, slideId: "slide", ownerUserId: session.ownerUserId,
            state: state
        )
        context.insert(upload)
        try context.save()
        return (queue, context, upload)
    }

    @MainActor
    func testOfflineUploadRemainsVisibleWithoutServerData() async throws {
        let (queue, _, upload) = try fixture(state: .pending)
        let presenter = AnalysisResultPresenter(interactor: OfflineResultInteractor(), uploadQueue: queue)
        await presenter.fetchData(examinationId: upload.examinationId)
        XCTAssertNil(presenter.examinationResult)
        XCTAssertEqual(presenter.localUploadState, .pending)
        XCTAssertTrue(presenter.shouldShowAnalyzingUI)
        XCTAssertFalse(presenter.hasAnalysisFailed)
    }

    @MainActor
    func testNotStartedDuringUploadDoesNotFailAnalysisOrClearTracking() async throws {
        for state in [PendingUploadState.pending, .uploading, .failed] {
            let (queue, _, upload) = try fixture(state: state)
            AnalysisTrackingStore.track(examinationId: upload.examinationId)
            defer { AnalysisTrackingStore.untrack(examinationId: upload.examinationId) }
            let presenter = AnalysisResultPresenter(interactor: StatusResultInteractor(status: .NOTSTARTED), uploadQueue: queue)
            await presenter.fetchData(examinationId: upload.examinationId)
            presenter.markAnalysisFailed(message: "Old cached failure", examinationId: upload.examinationId)
            XCTAssertEqual(presenter.localUploadState, state)
            XCTAssertFalse(presenter.hasAnalysisFailed)
            XCTAssertTrue(presenter.shouldShowAnalyzingUI)
            XCTAssertTrue(AnalysisTrackingStore.isTracked(upload.examinationId))
        }
    }

    @MainActor
    func testRetryKeepsSavedVideoInPendingPhaseOffline() async throws {
        let (queue, _, upload) = try fixture(state: .failed)
        upload.retryCount = 5
        upload.lastError = "Temporary network failure"
        let presenter = AnalysisResultPresenter(interactor: OfflineResultInteractor(), uploadQueue: queue)
        presenter.refreshLocalUploadState(examinationId: upload.examinationId)
        XCTAssertEqual(presenter.localUploadState, .failed)
        await presenter.retrySavedUpload(examinationId: upload.examinationId)
        XCTAssertEqual(presenter.localUploadState, .pending)
        XCTAssertNil(presenter.localUploadError)
        XCTAssertEqual(upload.retryCount, 0)
    }

    @MainActor
    func testAdmittedAnalysisAndFinishedResultsTakeOverLocalPhase() async throws {
        let (queue, context, upload) = try fixture(state: .pending)
        let examId = upload.examinationId
        let presenter = AnalysisResultPresenter(interactor: StatusResultInteractor(status: .INPROGRESS), uploadQueue: queue)
        await presenter.fetchData(examinationId: examId)
        XCTAssertEqual(presenter.localUploadState, .pending)
        context.delete(upload)
        try context.save()
        presenter.refreshLocalUploadState(examinationId: examId)
        XCTAssertNil(presenter.localUploadState)
        XCTAssertTrue(presenter.shouldShowAnalyzingUI)
        XCTAssertFalse(presenter.hasAnalysisFailed)

        let (finishedQueue, _, retainedUpload) = try fixture(state: .failed)
        let finished = AnalysisResultPresenter(interactor: StatusResultInteractor(status: .FINISHED), uploadQueue: finishedQueue)
        await finished.fetchData(examinationId: retainedUpload.examinationId)
        XCTAssertEqual(finished.localUploadState, .failed, "Finished status cannot acknowledge a different saved submission")
        XCTAssertTrue(finished.shouldShowResultsUI)
        XCTAssertFalse(finished.shouldShowAnalyzingUI, "Retained video must not block viewing clinical results")
    }

    @MainActor
    func testMissingFileOffersVideoRecoveryInsteadOfRetryingForever() async throws {
        let (queue, _, upload) = try fixture(state: .failed)
        try FileManager.default.removeItem(atPath: upload.localFilePath)
        let presenter = AnalysisResultPresenter(interactor: OfflineResultInteractor(), uploadQueue: queue)
        presenter.refreshLocalUploadState(examinationId: upload.examinationId)
        XCTAssertTrue(presenter.localUploadNeedsVideo)
        XCTAssertEqual(presenter.localUploadState, .failed)
    }

    @MainActor
    func testFetchStartedBeforeReceiptCannotFailNewlyAdmittedAnalysis() async throws {
        let (queue, context, upload) = try fixture(state: .uploading)
        let examId = upload.examinationId
        let started = expectation(description: "Preadmission request started")
        let gate = AdmissionGate()
        let interactor = AdmissionCrossingInteractor(gate: gate, onStart: { started.fulfill() })
        let presenter = AnalysisResultPresenter(interactor: interactor, uploadQueue: queue)
        AnalysisTrackingStore.track(examinationId: examId)
        defer { AnalysisTrackingStore.untrack(examinationId: examId) }
        let fetch = Task { await presenter.fetchData(examinationId: examId) }
        await fulfillment(of: [started], timeout: 2)
        context.delete(upload)
        try context.save()
        await gate.open()
        await fetch.value
        XCTAssertEqual(interactor.fetchCount, 2)
        XCTAssertEqual(presenter.examinationResult?.statusExamination, .INPROGRESS)
        XCTAssertNil(presenter.localUploadState)
        XCTAssertFalse(presenter.hasAnalysisFailed)
        XCTAssertTrue(AnalysisTrackingStore.isTracked(examId))
    }

    @MainActor
    func testUnavailableFreshStatusAfterReceiptKeepsWaitingAndCanRecover() async throws {
        let (queue, context, upload) = try fixture(state: .uploading)
        let id = upload.examinationId
        let started = expectation(description: "Request started before receipt")
        let gate = AdmissionGate()
        let interactor = AdmissionCrossingInteractor(gate: gate, failFirstFreshFetch: true, onStart: { started.fulfill() })
        let presenter = AnalysisResultPresenter(interactor: interactor, uploadQueue: queue)
        AnalysisTrackingStore.track(examinationId: id)
        defer { AnalysisTrackingStore.untrack(examinationId: id) }
        let fetch = Task { await presenter.fetchData(examinationId: id) }
        await fulfillment(of: [started], timeout: 2)
        context.delete(upload)
        try context.save()
        await gate.open()
        await fetch.value
        XCTAssertTrue(presenter.isAwaitingAdmissionStatus)
        XCTAssertTrue(presenter.shouldShowAnalyzingUI)
        presenter.markAnalysisFailed(message: "Stale failure", examinationId: id)
        XCTAssertFalse(presenter.hasAnalysisFailed)
        await presenter.fetchData(examinationId: id)
        XCTAssertFalse(presenter.isAwaitingAdmissionStatus)
        XCTAssertEqual(presenter.examinationResult?.statusExamination, .INPROGRESS)
        XCTAssertFalse(presenter.hasAnalysisFailed)
    }

    @MainActor
    func testCancelledPreadmissionFetchDoesNotStartAnotherRequest() async throws {
        let (queue, context, upload) = try fixture(state: .uploading)
        let id = upload.examinationId
        let started = expectation(description: "Preadmission request started")
        let gate = AdmissionGate()
        let interactor = AdmissionCrossingInteractor(gate: gate, onStart: { started.fulfill() })
        let presenter = AnalysisResultPresenter(interactor: interactor, uploadQueue: queue)
        let fetch = Task { await presenter.fetchData(examinationId: id) }
        await fulfillment(of: [started], timeout: 2)
        context.delete(upload)
        try context.save()
        fetch.cancel()
        await gate.open()
        await fetch.value
        XCTAssertEqual(interactor.fetchCount, 1)
        XCTAssertNil(presenter.examinationResult)
        XCTAssertFalse(presenter.isLoading)
    }

    @MainActor
    func testNotStartedWithoutLocalUploadStillReportsServerFailure() async {
        let queue = VideoUploadQueueService(sessionProvider: { nil })
        let id = UUID().uuidString
        AnalysisTrackingStore.track(examinationId: id)
        defer { AnalysisTrackingStore.untrack(examinationId: id) }
        let presenter = AnalysisResultPresenter(interactor: StatusResultInteractor(status: .NOTSTARTED), uploadQueue: queue)
        await presenter.fetchData(examinationId: id)
        XCTAssertTrue(presenter.hasAnalysisFailed)
    }

    @MainActor
    func testTrackerIgnoresPriorFailureUntilSavedUploadIsAdmitted() {
        var pending = true
        let tracker = AnalysisProgressTracker(hasPendingUpload: { _ in pending })
        tracker.evaluateHealth(examinationId: "exam", status: .NOTSTARTED, hasFOVData: false, isTracked: true)
        let failure = AnalysisProgressUpdate(examId: "exam", status: "failed", progress: 0, message: "Old failure", statusExamination: "NOTSTARTED", updatedAt: nil)
        tracker.applyProgressUpdate(failure, examinationId: "exam")
        XCTAssertFalse(tracker.hasAnalysisFailed)
        pending = false
        tracker.applyProgressUpdate(failure, examinationId: "exam")
        XCTAssertTrue(tracker.hasAnalysisFailed)
    }

    @MainActor
    func testLocalUploadCardsRenderAtSmallWidthAndLargeText() async throws {
        for state in [PendingUploadState.pending, .uploading, .failed] {
            let card = LocalUploadProgressCard(
                state: state,
                errorMessage: state == .failed ? AppTextExam.uploadQueueMaxRetries : nil
            )
            .padding(16)
            .frame(width: 320)
            .environment(\.dynamicTypeSize, .accessibility1)
            // Host native controls as well: ImageRenderer cannot draw the UIKit spinner.
            let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
            let controller = UIHostingController(rootView: card)
            controller.safeAreaRegions = []
            let size = controller.sizeThatFits(in: CGSize(width: 320, height: 10_000))
            let window = UIWindow(windowScene: scene)
            window.frame = CGRect(origin: .zero, size: size)
            window.rootViewController = controller
            window.isHidden = false
            defer { window.isHidden = true }
            controller.view.frame = window.bounds
            controller.view.layoutIfNeeded()
            await Task.yield()
            let image = UIGraphicsImageRenderer(size: size).image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
            XCTAssertGreaterThan(image.size.height, 150)
            let attachment = XCTAttachment(image: image)
            attachment.name = "local-upload-\(state.rawValue)"
            attachment.lifetime = .keepAlways
            add(attachment)
            if let data = image.pngData() {
                try data.write(to: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("oculab-local-upload-\(state.rawValue).png"))
            }
        }
    }
}

private final class OfflineResultInteractor: AnalysisResultInteractor {
    init() { super.init(networkService: MockNetworkService()) }
    override func fetchData(examId: String) async throws -> ExaminationResultData {
        throw URLError(.notConnectedToInternet)
    }
}

private final class StatusResultInteractor: AnalysisResultInteractor {
    let status: StatusType
    init(status: StatusType) {
        self.status = status
        super.init(networkService: MockNetworkService())
    }
    override func fetchData(examId: String) async throws -> ExaminationResultData {
        ExaminationResultData(examinationId: examId, slideId: "slide", imagePreview: "", fov: [], confidenceLevelAggregated: 0, systemGrading: .unknown, bacteriaTotalCount: 0, statusExamination: status)
    }
    override func fetchFOVData(examId: String) async throws -> FOVGrouping {
        try JSONDecoder().decode(FOVGrouping.self, from: Data("{}".utf8))
    }
}

private actor AdmissionGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var isOpen = false
    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { continuation = $0 }
    }
    func open() {
        isOpen = true
        continuation?.resume()
        continuation = nil
    }
}

private final class AdmissionCrossingInteractor: AnalysisResultInteractor {
    private let gate: AdmissionGate
    private let onStart: () -> Void
    private let failFirstFreshFetch: Bool
    var fetchCount = 0
    init(gate: AdmissionGate, failFirstFreshFetch: Bool = false, onStart: @escaping () -> Void) {
        self.failFirstFreshFetch = failFirstFreshFetch
        self.gate = gate
        self.onStart = onStart
        super.init(networkService: MockNetworkService())
    }
    override func fetchData(examId: String) async throws -> ExaminationResultData {
        fetchCount += 1
        if failFirstFreshFetch, fetchCount == 2 { throw URLError(.timedOut) }
        let first = fetchCount == 1
        if first {
            onStart()
            await gate.wait()
        }
        return ExaminationResultData(examinationId: examId, slideId: "slide", imagePreview: "", fov: [], confidenceLevelAggregated: 0, systemGrading: .unknown, bacteriaTotalCount: 0, statusExamination: first ? .NOTSTARTED : .INPROGRESS)
    }
}
