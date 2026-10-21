@preconcurrency import AVFoundation
import Foundation

@MainActor
protocol CameraCaptureControlling: AnyObject {
    var session: AVCaptureSession { get }
    var output: AVCaptureMovieFileOutput { get }

    func start(delegate: AVCaptureVideoDataOutputSampleBufferDelegate) async throws
    func stop()
    func waitForPendingOperations() async
    func startRecording(to url: URL, delegate: AVCaptureFileOutputRecordingDelegate,
                        completion: @escaping @MainActor (Result<Void, Error>) -> Void)
    func stopRecording()
    func setZoom(_ factor: CGFloat) async throws -> CGFloat
    func focus(at point: CGPoint) async throws
}

/// Synchronous capture operations, exclusively accessed on the controller's serial queue.
/// The stable session/output objects may also be attached to the main-thread preview.
protocol CameraCaptureGraph: AnyObject {
    var session: AVCaptureSession { get }
    var output: AVCaptureMovieFileOutput { get }

    func configure(delegate: AVCaptureVideoDataOutputSampleBufferDelegate) throws
    func start() throws
    func stop()
    func startRecording(to url: URL, delegate: AVCaptureFileOutputRecordingDelegate) throws
    func stopRecording()
    func setZoom(_ factor: CGFloat) throws -> CGFloat
    func focus(at point: CGPoint) throws
}

@MainActor
final class CameraCaptureController: CameraCaptureControlling {
    let session: AVCaptureSession
    let output: AVCaptureMovieFileOutput

    private let queue = DispatchQueue(label: "com.oculab.videorecord.capture", qos: .userInitiated)
    private let worker: CameraCaptureWorker

    init(graph: CameraCaptureGraph? = nil) {
        let graph = graph ?? HardwareCameraCaptureGraph()
        session = graph.session
        output = graph.output
        worker = CameraCaptureWorker(graph: graph)
    }

    func start(delegate: AVCaptureVideoDataOutputSampleBufferDelegate) async throws {
        try await perform { worker in
            try worker.start(delegate: delegate)
        }
    }

    func stop() {
        let worker = worker
        // Enqueue before returning to the caller. A subsequent startup cannot
        // overtake dismissal, even when the caller does not await cleanup.
        queue.async {
            worker.graph.stop()
        }
    }

    func waitForPendingOperations() async {
        await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume()
            }
        }
    }

    func startRecording(to url: URL, delegate: AVCaptureFileOutputRecordingDelegate,
                        completion: @escaping @MainActor (Result<Void, Error>) -> Void) {
        let worker = worker
        queue.async {
            let result: Result<Void, Error>
            do {
                try worker.graph.startRecording(to: url, delegate: delegate)
                result = .success(())
            } catch {
                result = .failure(error)
            }
            Task { @MainActor in
                completion(result)
            }
        }
    }

    func stopRecording() {
        let worker = worker
        queue.async {
            worker.graph.stopRecording()
        }
    }

    func setZoom(_ factor: CGFloat) async throws -> CGFloat {
        try await perform { worker in
            try worker.graph.setZoom(factor)
        }
    }

    func focus(at point: CGPoint) async throws {
        try await perform { worker in
            try worker.graph.focus(at: point)
        }
    }

    private func perform<Value>(_ operation: @escaping (CameraCaptureWorker) throws -> Value) async throws -> Value {
        try Task.checkCancellation()
        let worker = worker
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    continuation.resume(returning: try operation(worker))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

/// Mutable graph state has one owner: CameraCaptureController's serial queue.
private final class CameraCaptureWorker: @unchecked Sendable {
    let graph: CameraCaptureGraph
    private var isConfigured = false

    init(graph: CameraCaptureGraph) {
        self.graph = graph
    }

    func start(delegate: AVCaptureVideoDataOutputSampleBufferDelegate) throws {
        if !isConfigured {
            try graph.configure(delegate: delegate)
            isConfigured = true
        }
        // Each recording entry starts with the same zoom shown by the UI.
        _ = try graph.setZoom(1)
        try graph.start()
    }
}

private final class HardwareCameraCaptureGraph: CameraCaptureGraph {
    let session = AVCaptureSession()
    let output = AVCaptureMovieFileOutput()

    private let videoOutput = AVCaptureVideoDataOutput()
    private let frameProcessingQueue = DispatchQueue(
        label: "com.oculab.videorecord.frameProcessing",
        qos: .userInteractive
    )
    private var device: AVCaptureDevice?

    func configure(delegate: AVCaptureVideoDataOutputSampleBufferDelegate) throws {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraCaptureError.deviceUnavailable
        }
        let input = try AVCaptureDeviceInput(device: camera)

        session.beginConfiguration()
        defer { session.commitConfiguration() }
        do {
            guard session.canAddInput(input) else { throw CameraCaptureError.inputUnavailable }
            // Preserve the native session preset and frame rate; capture video only.
            session.addInput(input)
            try configureDevice(camera)

            guard session.canAddOutput(output) else { throw CameraCaptureError.outputUnavailable }
            session.addOutput(output)
            output.movieFragmentInterval = .invalid
            configureStabilization()

            guard session.canAddOutput(videoOutput) else { throw CameraCaptureError.outputUnavailable }
            session.addOutput(videoOutput)
            videoOutput.setSampleBufferDelegate(delegate, queue: frameProcessingQueue)
            device = camera
        } catch {
            // A later permission/device retry must begin from an empty graph,
            // rather than inheriting half of a failed configuration.
            videoOutput.setSampleBufferDelegate(nil, queue: nil)
            session.outputs.forEach { session.removeOutput($0) }
            session.inputs.forEach { session.removeInput($0) }
            device = nil
            throw error
        }
    }

    func start() throws {
        guard let device else { throw CameraCaptureError.deviceUnavailable }
        // Tap-to-focus uses single-shot focus/exposure. Restore continuous
        // capture settings for the next specimen without rebuilding the graph.
        try configureDevice(device)
        if !session.isRunning {
            session.startRunning()
        }
        guard session.isRunning else { throw CameraCaptureError.notRunning }
    }

    func stop() {
        stopRecording()
        if session.isRunning {
            session.stopRunning()
        }
    }

    func startRecording(to url: URL, delegate: AVCaptureFileOutputRecordingDelegate) throws {
        guard session.isRunning else { throw CameraCaptureError.notRunning }
        guard !output.isRecording else { throw CameraCaptureError.recordingInProgress }
        configureStabilization()
        output.startRecording(to: url, recordingDelegate: delegate)
    }

    func stopRecording() {
        if output.isRecording {
            output.stopRecording()
        }
    }

    func setZoom(_ factor: CGFloat) throws -> CGFloat {
        guard factor.isFinite else { throw CameraCaptureError.invalidZoom }
        guard let device else { throw CameraCaptureError.deviceUnavailable }
        let minimum = max(1, device.minAvailableVideoZoomFactor)
        let maximum = max(minimum, min(4.9, device.maxAvailableVideoZoomFactor))
        let clamped = min(max(factor, minimum), maximum)
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        device.videoZoomFactor = clamped
        return clamped
    }

    func focus(at point: CGPoint) throws {
        guard point.x.isFinite, point.y.isFinite else { throw CameraCaptureError.invalidFocusPoint }
        guard let device else { throw CameraCaptureError.deviceUnavailable }
        let clamped = CGPoint(x: min(max(point.x, 0), 1), y: min(max(point.y, 0), 1))
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        if device.isFocusPointOfInterestSupported, device.isFocusModeSupported(.autoFocus) {
            device.focusPointOfInterest = clamped
            device.focusMode = .autoFocus
        }
        if device.isExposurePointOfInterestSupported, device.isExposureModeSupported(.autoExpose) {
            device.exposurePointOfInterest = clamped
            device.exposureMode = .autoExpose
        }
    }

    private func configureDevice(_ device: AVCaptureDevice) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        if device.isSmoothAutoFocusSupported {
            device.isSmoothAutoFocusEnabled = true
        }
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }
        if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
            device.whiteBalanceMode = .continuousAutoWhiteBalance
        }
    }

    private func configureStabilization() {
        if let connection = output.connection(with: .video), connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = .auto
        }
    }
}

private enum CameraCaptureError: LocalizedError {
    case deviceUnavailable
    case inputUnavailable
    case outputUnavailable
    case notRunning
    case recordingInProgress
    case invalidZoom
    case invalidFocusPoint

    var errorDescription: String? {
        switch self {
        case .deviceUnavailable: return "Camera not available"
        case .inputUnavailable: return "Cannot add camera input"
        case .outputUnavailable: return "Cannot add recording output"
        case .notRunning: return "Camera could not start"
        case .recordingInProgress: return "A recording is already in progress"
        case .invalidZoom: return "Invalid camera zoom"
        case .invalidFocusPoint: return "Invalid camera focus point"
        }
    }
}
