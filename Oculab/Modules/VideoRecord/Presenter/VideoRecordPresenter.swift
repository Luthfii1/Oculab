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
    static let shared = VideoRecordPresenter(interactor: VideoInteractor())

    private let interactor: VideoInteractor

    init(interactor: VideoInteractor) {
        self.interactor = interactor
        super.init()
    }

    // MARK: - Enable/disable features
    private var isEnableSaveVideoToPhotos: Bool = false

    // MARK: - Published Properties
    @Published var session = AVCaptureSession()
    @Published var videoRecordingTitle: String = AppTextVideoRecordView.specimenTitleDefault
    @Published var alert = false
    @Published var output = AVCaptureMovieFileOutput()
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
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var recordingDuration: TimeInterval = 0.0
    @Published var recordingQuality: AVCaptureSession.Preset = .high

    // MARK: - Private Properties
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var lastStitchTime: Date?
    private let stitchInterval: TimeInterval = Stitch.clippingDuration
    private let minZoomFactor: CGFloat = 1.0
    private let maxZoomFactor: CGFloat = 4.9
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    private let frameProcessingQueue = DispatchQueue(
        label: "com.oculab.videorecord.frameProcessing",
        qos: .userInteractive
    )

    // MARK: - Constants
    let preRecordingInstructions: [String] = AppTextVideoRecordInstruction.preRecordingInstructions
    let duringRecordingInstructions: [String] = AppTextVideoRecordInstruction.duringRecordingInstructions

    // MARK: - Permission Management
    func checkPermission() async {
        await requestCameraPermission()
    }
    
    @MainActor
    private func requestCameraPermission() async {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraStatus {
        case .authorized:
            await setUp()
        case .notDetermined:
            let cameraGranted = await AVCaptureDevice.requestAccess(for: .video)
            
            if cameraGranted {
                await setUp()
            } else {
                alert = true
            }
        case .denied, .restricted:
            alert = true
        @unknown default:
            alert = true
        }
    }

    // MARK: - Camera Setup
    @MainActor
    private func setUp() async {
        isLoading = true
        defer { isLoading = false }

        session.beginConfiguration()

        do {
            removeExistingInputsAndOutputs()
            try setupInputs()
            setupOutputs()
            session.commitConfiguration()
        } catch {
            session.commitConfiguration()
            Logger.error("Camera setup failed: \(error.localizedDescription)", category: .videoRecord)
            errorMessage = "Failed to setup camera: \(error.localizedDescription)"
            return
        }

        await startCameraSession()
    }
    
    private func removeExistingInputsAndOutputs() {
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
    }
    
    private func setupInputs() throws {
        guard let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: cameraDevice)
        else {
            throw VideoRecordError.deviceNotFound
        }
        
        // Add video input only (audio disabled to reduce file size)
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            throw VideoRecordError.cannotAddInput
        }
        
        // Configure camera device
        try configureCameraDevice(cameraDevice)
    }
    
    private func setupOutputs() {
        // Setup movie file output
        if session.canAddOutput(output) {
            session.addOutput(output)
            configureMovieOutput()
        }
        
        // Setup video data output for frame processing
        videoDataOutput.setSampleBufferDelegate(self, queue: frameProcessingQueue)
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
        }
    }
    
    private func configureCameraDevice(_ device: AVCaptureDevice) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        
        // Set video zoom factor
        device.videoZoomFactor = zoomFactor
        
        // Enable smooth autofocus if available
        if device.isSmoothAutoFocusSupported {
            device.isSmoothAutoFocusEnabled = true
        }
        
        // Set focus mode
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }
        
        // Set exposure mode
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }
        
        // Set white balance mode
        if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
            device.whiteBalanceMode = .continuousAutoWhiteBalance
        }
    }
    
    private func configureMovieOutput() {
        output.movieFragmentInterval = .invalid // Disable fragmentation for better compatibility
        
        // Set connection properties
        if let connection = output.connection(with: .video) {
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
        }
    }
    
    @MainActor
    private func startCameraSession() async {
        guard !session.isRunning else { 
            Logger.info("AVCaptureSession already running", category: .videoRecord)
            return 
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                self.session.startRunning()
                Logger.info("AVCaptureSession started", category: .videoRecord)
                continuation.resume()
            }
        }
    }

    // MARK: - Camera Session Management

    @MainActor
    func stopCameraSession() async {
        guard session.isRunning else { 
            Logger.info("AVCaptureSession already stopped", category: .videoRecord)
            return 
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                self.session.stopRunning()
                Logger.info("AVCaptureSession stopped", category: .videoRecord)
                continuation.resume()
            }
        }
    }

    // MARK: - Recording Management
    @MainActor
    func startRecording() {
        guard !isRecording else { return }

        // Mark recording state before issuing I/O to prevent double-tap races
        isRecording = true
        recordingStartTime = Date()

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(AppTextVideoRecordView.videoFileDateAndExtension())

        configureRecordingQuality()

        output.startRecording(to: tempURL, recordingDelegate: self)
        startRecordingTimer()

        Logger.info("Recording started", category: .videoRecord)
    }


    @MainActor
    func stopRecording() {
        guard isRecording else { return }

        output.stopRecording()
        isRecording = false

        stopRecordingTimer()

        Logger.info("Recording stopped", category: .videoRecord)
    }
    
    private func configureRecordingQuality() {
        if let connection = output.connection(with: .video) {
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
        }
    }
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            
            Task { @MainActor in
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
            if let error = error {
                Logger.error("Recording error: \(error.localizedDescription)", category: .videoRecord)
                self.errorMessage = error.localizedDescription
                self.previewURL = nil
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
        Task {
            await performImageStitching(newImage: newImage, referenceImage: lastStitchedImage)
        }
    }
    
    private func performImageStitching(newImage: UIImage, referenceImage: UIImage) async {
        return await withCheckedContinuation { continuation in
            ImageRegistration.shared.register(
                floatingImage: newImage,
                referenceImage: referenceImage,
                registrationMechanism: .translational
            ) { [weak self] compositedImage, _ in
                Task { @MainActor in
                    self?.stitchedImage = compositedImage
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
        guard let videoInput = session.inputs
            .compactMap({ $0 as? AVCaptureDeviceInput })
            .first(where: { $0.device.hasMediaType(.video) })
        else { return }

        let cameraDevice = videoInput.device
        let clampedFactor = min(max(factor, minZoomFactor), maxZoomFactor)

        do {
            try cameraDevice.lockForConfiguration()
            cameraDevice.videoZoomFactor = clampedFactor
            cameraDevice.unlockForConfiguration()
            zoomFactor = clampedFactor
        } catch {
            Logger.error("Error setting zoom: \(error.localizedDescription)", category: .videoRecord)
            errorMessage = "Failed to adjust zoom"
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
    @MainActor
    func cleanup() async {
        // Stop recording cleanly if in progress so the timer is invalidated
        // and no orphan capture finishes after the view is gone.
        if isRecording {
            output.stopRecording()
        }
        stopRecordingTimer()
        await stopCameraSession()

        // Reset all state
        isRecording = false
        showPlayerView = false
        stitchedImage = nil
        progressImage = nil
        errorMessage = nil
        recordingDuration = 0.0
        zoomFactor = 1.0

        // Clear URLs but don't reset previewURL if it exists
        recordedURLs.removeAll()
        resetSpecimenTitle()

        Logger.info("VideoRecordPresenter cleaned up successfully", category: .videoRecord)
    }
    
    @MainActor
    func resetForNewSession() async {
        // Complete cleanup first
        await cleanup()
        
        // Reset preview URL for fresh start
        previewURL = nil
        hasTaken = false
        showPreview = false
        
        // Reinitialize camera if permissions are granted
        await checkPermission()
        
        Logger.info("VideoRecordPresenter reset for new session", category: .videoRecord)
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
