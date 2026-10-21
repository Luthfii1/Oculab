//
//  VideoRecordPresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 14/10/24.
//

import AVFoundation
import Foundation
import Photos
import SwiftUI
import CoreImage

@MainActor
class VideoRecordPresenter: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate,
    AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate
{
    private let interactor: VideoInteractor
    private let captureController: CameraCaptureControlling
    private let cameraAuthorization: @MainActor () async -> Bool
    private var startupTask: Task<Void, Never>?
    private var lifecycleID = UUID()
    private var activeRecordingURL: URL?

    init(
        interactor: VideoInteractor = VideoInteractor(),
        captureController: CameraCaptureControlling? = nil,
        cameraAuthorization: (@MainActor () async -> Bool)? = nil
    ) {
        self.interactor = interactor
        let controller = captureController ?? CameraCaptureController()
        self.captureController = controller
        self.session = controller.session
        self.output = controller.output
        self.cameraAuthorization = cameraAuthorization ?? Self.authorizeCamera
        super.init()
    }

    // MARK: - Enable/disable features
    private var isEnableSaveVideoToPhotos: Bool = false

    // MARK: - Published Properties
    let session: AVCaptureSession
    @Published var videoRecordingTitle: String = AppTextVideoRecordView.specimenTitleDefault
    @Published var alert = false
    let output: AVCaptureMovieFileOutput
    @Published var preview: AVCaptureVideoPreviewLayer!
    @Published var hasTaken: Bool = false
    @Published var isRecording: Bool = false
    @Published var showPlayerView: Bool = false
    @Published var recordedURLs: [URL] = []
    @Published var previewURL: URL?
    @Published var showPreview: Bool = false
    @Published var showRecordingTitle: Bool = true // currently disable the feature and make it true for always showing the title
    @Published var stitchedImage: UIImage?
    @Published var progressImage: UIImage?
    @Published var progressImageChecker: String = AppValue.empty
    @Published var zoomFactor: CGFloat = 1.0
    @Published private(set) var isCameraReady = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var recordingDuration: TimeInterval = 0.0
    @Published var recordingQuality: AVCaptureSession.Preset = .high

    // MARK: - Private Properties
    private var lastStitchTime: Date?
    private let stitchInterval: TimeInterval = Stitch.clippingDuration
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    // MARK: - Constants
    let preRecordingInstructions: [String] = AppTextVideoRecordInstruction.preRecordingInstructions
    let duringRecordingInstructions: [String] = AppTextVideoRecordInstruction.duringRecordingInstructions

    // MARK: - Camera Startup
    // Navigation never waits for this work. One task owns permission and startup;
    // the capture controller serializes all blocking AVFoundation operations.
    func checkPermission() async {
        guard !Task.isCancelled, !isCameraReady, previewURL == nil else { return }
        if let startupTask {
            await startupTask.value
            return
        }

        let generation = lifecycleID
        isLoading = true
        alert = false
        errorMessage = nil
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            let granted = await self.cameraAuthorization()
            guard self.lifecycleID == generation, !Task.isCancelled else { return }
            guard granted else {
                self.alert = true
                self.isLoading = false
                self.startupTask = nil
                return
            }
            do {
                try await self.captureController.start(delegate: self)
                guard self.lifecycleID == generation, !Task.isCancelled else { return }
                self.isCameraReady = true
            } catch {
                guard self.lifecycleID == generation, !Task.isCancelled else { return }
                Logger.error("Camera setup failed: \(error.localizedDescription)", category: .videoRecord)
                self.errorMessage = "Failed to setup camera: \(error.localizedDescription)"
            }
            self.isLoading = false
            self.startupTask = nil
        }
        startupTask = task
        await task.value
    }

    func retryCameraStartup() async {
        // Recoverable recording/zoom errors can leave capture ready already.
        // Clear the alert even when no hardware restart is necessary.
        errorMessage = nil
        await checkPermission()
    }

    private static func authorizeCamera() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    func cancelCameraStartup() {
        lifecycleID = UUID()
        startupTask?.cancel()
        startupTask = nil
        isLoading = false
        isCameraReady = false
    }

    func stopCameraSession() async {
        cancelCameraStartup()
        captureController.stop()
    }

    // MARK: - Recording Management
    @MainActor
    func startRecording() {
        guard isCameraReady, !isRecording, activeRecordingURL == nil else { return }

        // Mark recording state before issuing I/O to prevent double-tap races
        isRecording = true
        recordingStartTime = Date()

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("oculab-\(UUID().uuidString).mov")

        activeRecordingURL = tempURL
        let generation = lifecycleID
        startRecordingTimer()
        captureController.startRecording(to: tempURL, delegate: self) { [weak self] result in
            guard let self, self.lifecycleID == generation,
                  self.activeRecordingURL == tempURL else { return }
            if case .failure(let error) = result {
                self.activeRecordingURL = nil
                self.isRecording = false
                self.isCameraReady = false
                self.stopRecordingTimer()
                self.errorMessage = "Failed to start recording: \(error.localizedDescription)"
            }
        }

        Logger.info("Recording started", category: .videoRecord)
    }


    @MainActor
    func stopRecording() {
        guard isRecording else { return }

        captureController.stopRecording()
        isRecording = false
        // Wait for the movie file to finish before allowing another recording.
        isCameraReady = false

        stopRecordingTimer()

        Logger.info("Recording stopped", category: .videoRecord)
    }
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let startTime = self.recordingStartTime else { return }
                self.recordingDuration = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingDuration = 0.0
    }

    // MARK: - AVCaptureFileOutputRecordingDelegate
    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        Task { @MainActor in
            // A dismissed recording must never replace a newer specimen preview.
            guard self.activeRecordingURL == outputFileURL else {
                self.deleteTemporaryFile(at: outputFileURL)
                return
            }
            self.activeRecordingURL = nil
            self.isRecording = false
            self.stopRecordingTimer()
            if let error = error {
                Logger.error("Recording error: \(error.localizedDescription)", category: .videoRecord)
                self.errorMessage = error.localizedDescription
                self.previewURL = nil
                self.isCameraReady = true
                self.deleteTemporaryFile(at: outputFileURL)
                return
            }

            Logger.info("Recording finished successfully", category: .videoRecord)
            self.previewURL = outputFileURL
            await self.stopCameraSession()
        }
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        Task { @MainActor [weak self] in
            guard let self = self, self.isRecording else { return }
            self.processFrameForStitching(pixelBuffer: pixelBuffer)
        }
    }

    @MainActor
    private func processFrameForStitching(pixelBuffer: CVPixelBuffer) {
        // Check if enough time has passed since last stitch
        let currentTime = Date()
        if let lastTime = lastStitchTime,
           currentTime.timeIntervalSince(lastTime) < stitchInterval {
            return
        }

        lastStitchTime = currentTime

        // Convert pixel buffer to UIImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage)

        stitchNewFrame(uiImage)
    }
    
    // MARK: - UI State Management
    @MainActor
    func handleButtonRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    // MARK: - Image Stitching
    @MainActor
    func stitchNewFrame(_ newImage: UIImage) {
        guard let lastStitchedImage = stitchedImage else {
            // First image, set as the stitched image
            stitchedImage = newImage
            return
        }

        // Perform stitching on background queue
        let generation = lifecycleID
        Task {
            await performImageStitching(newImage: newImage, referenceImage: lastStitchedImage, generation: generation)
        }
    }

    private func performImageStitching(newImage: UIImage, referenceImage: UIImage, generation: UUID) async {
        guard generation == lifecycleID else { return }
        return await withCheckedContinuation { continuation in
            ImageRegistration.shared.register(
                floatingImage: newImage,
                referenceImage: referenceImage,
                registrationMechanism: .translational
            ) { [weak self] compositedImage, _ in
                Task { @MainActor in
                    guard let self, self.lifecycleID == generation else { return }
                    self.stitchedImage = compositedImage
                }
                continuation.resume()
            }
        }
    }

    // MARK: - UI Helper Methods
    func getIconButtonRecording() -> String {
        return isRecording ? AppIcon.circleFill : AppIcon.buttonProgrammable
    }

    func getColorButtonRecording() -> Color {
        return isRecording ? .red : .white
    }

    func isBackButtonActive() -> Bool {
        return previewURL == nil && !isRecording
    }

    func isInformationButtonActive() -> Bool {
        return previewURL == nil && !isRecording
    }
    
    func getFormattedRecordingDuration() -> String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Navigation
    func navigateBack() {
        Router.shared.navigateBack()
    }

    // MARK: - Video Management
    @MainActor
    func saveVideoToPhotos() async {
        guard let videoURL = previewURL else {
            errorMessage = "No video available to save"
            return
        }
        
        isLoading = true
        defer { isLoading = false }

        do {
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            
            guard status == .authorized else {
                errorMessage = "Photo library access denied"
                return
            }
            
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }
            
            Logger.info("Video saved successfully to Photos", category: .videoRecord)
            Router.shared.popToRoot()
            
        } catch {
            Logger.error("Error saving video: \(error.localizedDescription)", category: .videoRecord)
            errorMessage = "Failed to save video: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func saveVideoWithoutNavigation() async {
        guard isEnableSaveVideoToPhotos else { return }
        guard let videoURL = previewURL else {
            errorMessage = "No video available to save"
            return
        }
        
        isLoading = true
        defer { isLoading = false }

        do {
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            
            guard status == .authorized else {
                errorMessage = "Photo library access denied"
                return
            }
            
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }
            
            Logger.info("Video saved successfully to Photos", category: .videoRecord)
            // Don't navigate - let the calling component handle navigation
            
        } catch {
            Logger.error("Error saving video: \(error.localizedDescription)", category: .videoRecord)
            errorMessage = "Failed to save video: \(error.localizedDescription)"
        }
    }

    // MARK: - Camera Controls
    @MainActor
    func updateZoom(factor: CGFloat) {
        guard isCameraReady else { return }
        let generation = lifecycleID
        Task {
            guard generation == lifecycleID, isCameraReady else { return }
            do {
                let actualZoom = try await captureController.setZoom(factor)
                guard generation == lifecycleID else { return }
                zoomFactor = actualZoom
            } catch {
                guard generation == lifecycleID else { return }
                errorMessage = "Failed to adjust zoom"
            }
        }
    }

    func focusCamera(at point: CGPoint) async {
        guard isCameraReady else { return }
        let generation = lifecycleID
        do {
            try await captureController.focus(at: point)
        } catch {
            guard generation == lifecycleID else { return }
            Logger.error("Error focusing camera: \(error.localizedDescription)", category: .videoRecord)
        }
    }

    @MainActor
    @discardableResult
    func deleteTemporaryFile(at url: URL) -> Bool {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.path) else { return true }
        do {
            try fileManager.removeItem(at: url)
            Logger.info("Temporary recording removed", category: .videoRecord)
            return true
        } catch {
            Logger.error("Failed to remove temporary recording: \(error.localizedDescription)", category: .videoRecord)
            return false
        }
    }
    
    // MARK: - Specimen Management
    func setSpecimenTitle(specimenId: String) {
        videoRecordingTitle = AppTextVideoRecordView.specimenTitle(specimenId)
    }
    
    func resetSpecimenTitle() {
        videoRecordingTitle = AppTextVideoRecordView.specimenTitleDefault
    }
    
    // MARK: - Cleanup
    // Synchronous invalidation and enqueueing are essential: an old disappearance
    // must not stop or reset a camera that has already been opened again.
    func endSession() {
        cancelCameraStartup()
        activeRecordingURL = nil
        captureController.stopRecording()
        captureController.stop()
        stopRecordingTimer()
        isRecording = false
        showPlayerView = false
        stitchedImage = nil
        progressImage = nil
        lastStitchTime = nil
        errorMessage = nil
        recordingStartTime = nil
        zoomFactor = 1.0
        recordedURLs.removeAll()
        resetSpecimenTitle()
    }

    func cleanup() async {
        endSession()
        // A replacement presenter must not acquire hardware while the previous
        // session still owns it. No UI state is changed after this suspension.
        await captureController.waitForPendingOperations()
    }

    func prepareForNewSession() {
        endSession()
        previewURL = nil
        hasTaken = false
        showPreview = false
        alert = false
    }

    func resetForNewSession() async {
        prepareForNewSession()
        await checkPermission()
    }
}

// MARK: - VideoRecordError
enum VideoRecordError: LocalizedError {
    case deviceNotFound
    case cannotAddInput
    case cannotAddOutput
    case recordingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .deviceNotFound:
            return "Camera not available"
        case .cannotAddInput:
            return "Cannot add camera input"
        case .cannotAddOutput:
            return "Cannot add recording output"
        case .recordingFailed(let message):
            return "Recording failed: \(message)"
        }
    }
}
