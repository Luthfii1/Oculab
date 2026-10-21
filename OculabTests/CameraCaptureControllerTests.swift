import AVFoundation
import XCTest
@testable import Oculab

final class CameraCaptureControllerTests: XCTestCase {
    @MainActor
    func testCancelledStartupDoesNotAcquireCaptureHardware() async {
        let graph = CaptureGraphSpy()
        let controller = CameraCaptureController(graph: graph)
        let request = Task { try await controller.start(delegate: CaptureDelegate()) }
        request.cancel()
        do {
            try await request.value
            XCTFail("A canceled destination must not start capture")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
        await controller.waitForPendingOperations()
        XCTAssertTrue(graph.events.isEmpty)
    }

    @MainActor
    func testReusesCaptureGraphAndResetsZoomOnEachStartOffTheMainThread() async throws {
        let graph = CaptureGraphSpy()
        let controller = CameraCaptureController(graph: graph)
        let delegate = CaptureDelegate()
        XCTAssertTrue(controller.session === graph.session)
        XCTAssertTrue(controller.output === graph.output)

        try await controller.start(delegate: delegate)
        let zoom = try await controller.setZoom(3)
        XCTAssertEqual(zoom, 3)
        try await controller.focus(at: CGPoint(x: 0.25, y: 0.75))
        controller.startRecording(to: URL(fileURLWithPath: "/tmp/capture-controller-test.mov"), delegate: delegate) { _ in }
        controller.stopRecording()
        controller.stop()
        try await controller.start(delegate: delegate)
        controller.stop()
        await controller.waitForPendingOperations()

        XCTAssertEqual(graph.events, [
            "configure", "zoom:1.0", "start", "zoom:3.0", "focus:0.25,0.75",
            "record:capture-controller-test.mov", "stopRecording", "stop",
            "zoom:1.0", "start", "stop"
        ])
        XCTAssertFalse(graph.observedMainThread)
        XCTAssertTrue(controller.session === graph.session)
        XCTAssertTrue(controller.output === graph.output)
    }

    @MainActor
    func testSynchronousStopRemainsQueuedBehindBlockedConfiguration() async throws {
        let graph = CaptureGraphSpy()
        let configureEntered = expectation(description: "Background graph configuration entered")
        let gate = DispatchSemaphore(value: 0)
        graph.onConfigure = {
            configureEntered.fulfill()
            _ = gate.wait(timeout: .now() + 5)
        }
        let controller = CameraCaptureController(graph: graph)
        let delegate = CaptureDelegate()
        let start = Task { try await controller.start(delegate: delegate) }
        await fulfillment(of: [configureEntered], timeout: 2)

        // These synchronous entry points must enqueue now, even while the
        // main actor remains available and the capture queue is still busy.
        controller.startRecording(to: URL(fileURLWithPath: "/tmp/ordered-recording.mov"), delegate: delegate) { _ in }
        controller.stopRecording()
        controller.stop()
        XCTAssertEqual(graph.events, ["configure"])

        gate.signal()
        try await start.value
        await controller.waitForPendingOperations()
        XCTAssertEqual(graph.events, [
            "configure", "zoom:1.0", "start", "record:ordered-recording.mov", "stopRecording", "stop"
        ])
        XCTAssertFalse(graph.observedMainThread)
    }

    @MainActor
    func testDrainWaitsForAQueuedStopBeforeAllowingReplacement() async throws {
        let graph = CaptureGraphSpy()
        let stopEntered = expectation(description: "Stop reached capture queue")
        let gate = DispatchSemaphore(value: 0)
        graph.onStop = {
            stopEntered.fulfill()
            _ = gate.wait(timeout: .now() + 5)
        }
        let controller = CameraCaptureController(graph: graph)
        try await controller.start(delegate: CaptureDelegate())
        controller.stop()
        await fulfillment(of: [stopEntered], timeout: 2)

        var finishedDraining = false
        let drain = Task {
            await controller.waitForPendingOperations()
            finishedDraining = true
        }
        await Task.yield()
        XCTAssertFalse(finishedDraining)
        gate.signal()
        await drain.value
        XCTAssertTrue(finishedDraining)
        XCTAssertEqual(graph.events.last, "stopCompleted")
    }

    @MainActor
    func testConfigurationFailureIsReturnedAndCanBeRetried() async throws {
        let graph = CaptureGraphSpy()
        graph.configureFailures = 1
        let controller = CameraCaptureController(graph: graph)
        let delegate = CaptureDelegate()
        do {
            try await controller.start(delegate: delegate)
            XCTFail("A failed graph configuration must not report camera readiness")
        } catch {
            XCTAssertEqual(error as? CaptureTestError, .configuration)
        }
        try await controller.start(delegate: delegate)
        XCTAssertEqual(graph.events, ["configure", "configure", "zoom:1.0", "start"])
        XCTAssertFalse(graph.observedMainThread)
    }

    @MainActor
    func testStartFailureIsReturnedWithoutRebuildingConfiguredGraphOnRetry() async throws {
        let graph = CaptureGraphSpy()
        graph.startFailures = 1
        let controller = CameraCaptureController(graph: graph)
        let delegate = CaptureDelegate()
        do {
            try await controller.start(delegate: delegate)
            XCTFail("A session that failed to start must not report camera readiness")
        } catch {
            XCTAssertEqual(error as? CaptureTestError, .startup)
        }
        try await controller.start(delegate: delegate)
        XCTAssertEqual(graph.events, ["configure", "zoom:1.0", "start", "zoom:1.0", "start"])
    }

    @MainActor
    func testZoomAndFocusErrorsPropagateWithoutBlockingLaterOperations() async throws {
        let graph = CaptureGraphSpy()
        graph.zoomFailureFactor = 7
        graph.focusFailurePoint = CGPoint(x: 0.5, y: 0.5)
        let controller = CameraCaptureController(graph: graph)
        try await controller.start(delegate: CaptureDelegate())
        do {
            _ = try await controller.setZoom(7)
            XCTFail("Zoom error must reach the caller")
        } catch {
            XCTAssertEqual(error as? CaptureTestError, .zoom)
        }
        do {
            try await controller.focus(at: CGPoint(x: 0.5, y: 0.5))
            XCTFail("Focus error must reach the caller")
        } catch {
            XCTAssertEqual(error as? CaptureTestError, .focus)
        }
        let appliedZoom = try await controller.setZoom(2)
        XCTAssertEqual(appliedZoom, 2)
        controller.stop()
        await controller.waitForPendingOperations()
        XCTAssertEqual(graph.events.last, "stop")
        XCTAssertFalse(graph.observedMainThread)
    }

    @MainActor
    func testRejectedRecordingReportsFailureOnMainActorAndQueueContinues() async throws {
        let graph = CaptureGraphSpy()
        graph.recordingFailures = 1
        let controller = CameraCaptureController(graph: graph)
        let delegate = CaptureDelegate()
        try await controller.start(delegate: delegate)
        let rejected = expectation(description: "Recording rejection delivered on main actor")
        controller.startRecording(to: URL(fileURLWithPath: "/tmp/rejected-recording.mov"), delegate: delegate) { result in
            XCTAssertTrue(Thread.isMainThread)
            switch result {
            case .success:
                XCTFail("A graph rejection must not be reported as a recording start")
            case .failure(let error):
                XCTAssertEqual(error as? CaptureTestError, .recording)
            }
            rejected.fulfill()
        }
        // A rejection must not poison the queue or swallow a later stop.
        controller.stop()
        await controller.waitForPendingOperations()
        await fulfillment(of: [rejected], timeout: 2)
        XCTAssertEqual(graph.events, ["configure", "zoom:1.0", "start", "record:rejected-recording.mov", "stop"])
        XCTAssertFalse(graph.observedMainThread)
    }
}

private enum CaptureTestError: Error, Equatable {
    case configuration, startup, zoom, focus, recording
}

private final class CaptureDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection], error: Error?) {}
}

private final class CaptureGraphSpy: CameraCaptureGraph {
    let session = AVCaptureSession()
    let output = AVCaptureMovieFileOutput()
    var onConfigure: (() -> Void)?
    var onStop: (() -> Void)?
    var configureFailures = 0
    var startFailures = 0
    var recordingFailures = 0
    var zoomFailureFactor: CGFloat?
    var focusFailurePoint: CGPoint?

    private let lock = NSLock()
    private var recordedEvents: [String] = []
    private var didRunOnMainThread = false

    var events: [String] {
        lock.lock()
        defer { lock.unlock() }
        return recordedEvents
    }

    var observedMainThread: Bool {
        lock.lock()
        defer { lock.unlock() }
        return didRunOnMainThread
    }

    private func record(_ event: String) {
        lock.lock()
        defer { lock.unlock() }
        recordedEvents.append(event)
        didRunOnMainThread = didRunOnMainThread || Thread.isMainThread
    }

    func configure(delegate: AVCaptureVideoDataOutputSampleBufferDelegate) throws {
        record("configure")
        onConfigure?()
        if configureFailures > 0 {
            configureFailures -= 1
            throw CaptureTestError.configuration
        }
    }

    func start() throws {
        record("start")
        if startFailures > 0 {
            startFailures -= 1
            throw CaptureTestError.startup
        }
    }

    func stop() {
        record("stop")
        if let onStop {
            onStop()
            record("stopCompleted")
        }
    }

    func startRecording(to url: URL, delegate: AVCaptureFileOutputRecordingDelegate) throws {
        record("record:\(url.lastPathComponent)")
        if recordingFailures > 0 {
            recordingFailures -= 1
            throw CaptureTestError.recording
        }
    }

    func stopRecording() {
        record("stopRecording")
    }

    func setZoom(_ factor: CGFloat) throws -> CGFloat {
        record("zoom:\(factor)")
        if factor == zoomFailureFactor { throw CaptureTestError.zoom }
        return factor
    }

    func focus(at point: CGPoint) throws {
        record("focus:\(point.x),\(point.y)")
        if point == focusFailurePoint { throw CaptureTestError.focus }
    }
}
