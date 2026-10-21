import AVFoundation
import Combine
import XCTest
@testable import Oculab

final class CameraStartupTests: XCTestCase {
    @MainActor
    func testConcurrentStartupRequestsSharePermissionAndCaptureWork() async {
        let capture = CameraStartupCaptureSpy()
        let gate = CameraStartupGate()
        let entered = expectation(description: "Permission requested")
        var requests = 0
        let presenter = VideoRecordPresenter(captureController: capture, cameraAuthorization: {
            requests += 1
            entered.fulfill()
            await gate.wait()
            return true
        })
        let first = Task { await presenter.checkPermission() }
        await fulfillment(of: [entered], timeout: 5)
        let secondEntered = expectation(description: "Second caller joined")
        let second = Task {
            secondEntered.fulfill()
            await presenter.checkPermission()
        }
        await fulfillment(of: [secondEntered], timeout: 5)
        XCTAssertTrue(presenter.isLoading)
        XCTAssertFalse(presenter.isCameraReady)
        presenter.startRecording()
        XCTAssertTrue(capture.recordedURLs.isEmpty)
        await gate.open()
        await first.value
        await second.value
        XCTAssertEqual(requests, 1)
        XCTAssertEqual(capture.starts, 1)
        XCTAssertTrue(presenter.isCameraReady)
        XCTAssertFalse(presenter.isLoading)
        await presenter.checkPermission()
        XCTAssertEqual(capture.starts, 1, "An already-ready camera must not be rebuilt")
        presenter.endSession()
    }

    @MainActor
    func testLeavingDuringPermissionRequestCannotStartCameraOrShowLateDenial() async {
        for granted in [true, false] {
            let capture = CameraStartupCaptureSpy()
            let gate = CameraStartupGate()
            let entered = expectation(description: "Permission dialog pending")
            let presenter = VideoRecordPresenter(captureController: capture, cameraAuthorization: {
                entered.fulfill()
                await gate.wait()
                return granted
            })
            let request = Task { await presenter.checkPermission() }
            await fulfillment(of: [entered], timeout: 5)
            presenter.endSession()
            await gate.open()
            await request.value
            XCTAssertEqual(capture.starts, 0)
            XCTAssertFalse(presenter.isLoading)
            XCTAssertFalse(presenter.isCameraReady)
            XCTAssertFalse(presenter.alert)
        }
    }

    @MainActor
    func testOldStartupCompletionCannotOverwriteImmediatelyReopenedCamera() async {
        let capture = CameraStartupCaptureSpy()
        let gate = CameraStartupGate()
        let entered = expectation(description: "First hardware start held")
        capture.onStart = { attempt in
            if attempt == 1 {
                entered.fulfill()
                await gate.wait()
                throw CameraStartupTestError.failed
            }
        }
        let presenter = VideoRecordPresenter(captureController: capture, cameraAuthorization: { true })
        let first = Task { await presenter.checkPermission() }
        await fulfillment(of: [entered], timeout: 5)
        presenter.endSession()
        presenter.prepareForNewSession()
        await presenter.checkPermission()
        XCTAssertTrue(presenter.isCameraReady)
        let stopsBeforeOldCompletion = capture.stops
        await gate.open()
        await first.value
        XCTAssertTrue(presenter.isCameraReady)
        XCTAssertFalse(presenter.isLoading)
        XCTAssertNil(presenter.errorMessage)
        XCTAssertEqual(capture.stops, stopsBeforeOldCompletion, "Old completion must not stop the new session")
        presenter.endSession()
    }

    @MainActor
    func testPermissionDenialAndSetupFailureCanRetryWithoutFalseReadiness() async {
        let capture = CameraStartupCaptureSpy()
        var authorized = false
        let presenter = VideoRecordPresenter(captureController: capture, cameraAuthorization: { authorized })
        await presenter.checkPermission()
        XCTAssertTrue(presenter.alert)
        XCTAssertFalse(presenter.isCameraReady)
        XCTAssertFalse(presenter.isLoading)
        XCTAssertEqual(capture.starts, 0)
        authorized = true
        capture.onStart = { _ in throw CameraStartupTestError.failed }
        await presenter.checkPermission()
        XCTAssertFalse(presenter.alert)
        XCTAssertNotNil(presenter.errorMessage)
        XCTAssertFalse(presenter.isCameraReady)
        XCTAssertFalse(presenter.isLoading)
        capture.onStart = { _ in }
        await presenter.checkPermission()
        XCTAssertNil(presenter.errorMessage)
        XCTAssertTrue(presenter.isCameraReady)
        presenter.endSession()
    }

    @MainActor
    func testPreviewIsPreservedUntilExplicitRetakeAndRetakeStartsAgain() async {
        let capture = CameraStartupCaptureSpy()
        let presenter = VideoRecordPresenter(captureController: capture, cameraAuthorization: { true })
        await presenter.checkPermission()
        let preview = URL(fileURLWithPath: "/tmp/oculab-camera-preview.mov")
        presenter.previewURL = preview
        presenter.endSession()
        await presenter.checkPermission()
        XCTAssertEqual(presenter.previewURL, preview)
        XCTAssertEqual(capture.starts, 1)
        presenter.prepareForNewSession()
        XCTAssertNil(presenter.previewURL)
        await presenter.checkPermission()
        XCTAssertEqual(capture.starts, 2)
        XCTAssertTrue(presenter.isCameraReady)
        presenter.endSession()
    }

    @MainActor
    func testRejectedRecordingClearsBusyStateAndCanRetry() async {
        let capture = CameraStartupCaptureSpy()
        let presenter = VideoRecordPresenter(captureController: capture, cameraAuthorization: { true })
        await presenter.checkPermission()
        capture.recordingResult = .failure(CameraStartupTestError.failed)
        presenter.startRecording()
        XCTAssertFalse(presenter.isRecording)
        XCTAssertFalse(presenter.isCameraReady)
        XCTAssertNotNil(presenter.errorMessage)
        XCTAssertEqual(presenter.recordingDuration, 0)
        capture.recordingResult = .success(())
        await presenter.checkPermission()
        presenter.startRecording()
        XCTAssertTrue(presenter.isRecording)
        XCTAssertNil(presenter.errorMessage)
        XCTAssertEqual(capture.recordedURLs.count, 2)
        presenter.endSession()
    }

    @MainActor
    func testDismissedRecordingCannotReplaceNewRecordingPreview() async {
        let capture = CameraStartupCaptureSpy()
        let presenter = CameraRecordingCallbackSpy(captureController: capture, cameraAuthorization: { true })
        await presenter.checkPermission()
        presenter.startRecording()
        guard let oldURL = capture.recordedURLs.first else { return XCTFail("First recording should start") }
        presenter.stopRecording()
        presenter.startRecording()
        XCTAssertEqual(capture.recordedURLs.count, 1, "A finalizing file must not accept another recording")
        presenter.prepareForNewSession()
        await presenter.checkPermission()
        presenter.startRecording()
        guard let newURL = capture.recordedURLs.last else { return XCTFail("New recording should start") }
        XCTAssertNotEqual(oldURL, newURL, "Rapid retakes must never reuse the old writer's URL")
        let oldFileRemoved = expectation(description: "Stale movie callback processed")
        presenter.onDelete = { url in
            if url == oldURL { oldFileRemoved.fulfill() }
        }
        presenter.fileOutput(capture.output, didFinishRecordingTo: oldURL, from: [], error: nil)
        await fulfillment(of: [oldFileRemoved], timeout: 5)
        XCTAssertNil(presenter.previewURL)
        XCTAssertTrue(presenter.isRecording)
        presenter.stopRecording()
        let finished = expectation(description: "Current movie callback processed")
        let previewObservation = presenter.$previewURL.sink { url in
            if url == newURL { finished.fulfill() }
        }
        presenter.fileOutput(capture.output, didFinishRecordingTo: newURL, from: [], error: nil)
        await fulfillment(of: [finished], timeout: 5)
        withExtendedLifetime(previewObservation) {}
        XCTAssertEqual(presenter.previewURL, newURL)
        XCTAssertFalse(presenter.isRecording)
        presenter.endSession()
    }
}

@MainActor
private final class CameraStartupCaptureSpy: CameraCaptureControlling {
    let session = AVCaptureSession()
    let output = AVCaptureMovieFileOutput()
    var starts = 0
    var stops = 0
    var recordedURLs: [URL] = []
    var onStart: (Int) async throws -> Void = { _ in }
    func start(delegate: AVCaptureVideoDataOutputSampleBufferDelegate) async throws {
        starts += 1
        try await onStart(starts)
    }
    func stop() { stops += 1 }
    func waitForPendingOperations() async {}
    var recordingResult: Result<Void, Error> = .success(())
    func startRecording(to url: URL, delegate: AVCaptureFileOutputRecordingDelegate,
                        completion: @escaping @MainActor (Result<Void, Error>) -> Void) {
        recordedURLs.append(url)
        completion(recordingResult)
    }
    func stopRecording() {}
    func setZoom(_ factor: CGFloat) async throws -> CGFloat { factor }
    func focus(at point: CGPoint) async throws {}
}

private actor CameraStartupGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var opened = false
    func wait() async {
        if opened { return }
        await withCheckedContinuation { continuation = $0 }
    }
    func open() {
        opened = true
        continuation?.resume()
        continuation = nil
    }
}

private enum CameraStartupTestError: Error { case failed }

@MainActor
private final class CameraRecordingCallbackSpy: VideoRecordPresenter {
    var onDelete: (URL) -> Void = { _ in }
    override func deleteTemporaryFile(at url: URL) -> Bool {
        onDelete(url)
        return true
    }
}
