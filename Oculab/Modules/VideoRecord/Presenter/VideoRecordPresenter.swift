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
    @Published var showRecordingTitle: Bool = false
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
    private let frameProcessingQueue = DispatchQueue(label: "frameProcessingQueue", qos: .userInteractive)

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
        let microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch (cameraStatus, microphoneStatus) {
        case (.authorized, .authorized):
            await setUp()
        case (.notDetermined, _), (_, .notDetermined):
            let cameraGranted = await AVCaptureDevice.requestAccess(for: .video)
            let microphoneGranted = await AVCaptureDevice.requestAccess(for: .audio)
            
            if cameraGranted && microphoneGranted {
                await setUp()
            } else {
                alert = true
            }
        case (.denied, _), (.restricted, _), (_, .denied), (_, .restricted):
            alert = true
        default:
            alert = true
        }
    }

    // MARK: - Camera Setup
    @MainActor
    private func setUp() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            session.beginConfiguration()
            
            // Remove existing inputs and outputs
            removeExistingInputsAndOutputs()
            
            // Setup camera and audio inputs
            try await setupInputs()
            
            // Setup outputs
            setupOutputs()
            
            session.commitConfiguration()
            
            await startCameraSession()
            
        } catch {
            print("Setup error: \(error.localizedDescription)")
            errorMessage = "Failed to setup camera: \(error.localizedDescription)"
        }
    }
    
    private func removeExistingInputsAndOutputs() {
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
    }
    
    private func setupInputs() throws {
        guard let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: cameraDevice),
              let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice)
        else {
            throw VideoRecordError.deviceNotFound
        }
        
        // Add video input
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            throw VideoRecordError.cannotAddInput
        }
        
        // Add audio input
        if session.canAddInput(audioInput) {
            session.addInput(audioInput)
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
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(AppTextVideoRecordView.videoFileDateAndExtension())
        
        // Configure recording quality
        configureRecordingQuality()
        
        output.startRecording(to: tempURL, recordingDelegate: self)
        isRecording = true
        recordingStartTime = Date()
        showRecordingTitle = true
        
        startRecordingTimer()
        
        Logger.info("Recording started at: \(tempURL.lastPathComponent)", category: .videoRecord)
    }
    
    @MainActor
    func stopRecording() {
        guard isRecording else { return }
        
        output.stopRecording()
        isRecording = false
        showRecordingTitle = false
        
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
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        Task { @MainActor in
            if let error = error {
                Logger.error("Recording error: \(error.localizedDescription)", category: .videoRecord)
                errorMessage = error.localizedDescription
                previewURL = nil
                return
            }

            Logger.info("Recording finished: \(outputFileURL.lastPathComponent)", category: .videoRecord)
            previewURL = outputFileURL
            await stopCameraSession()
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard isRecording,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Process frame for stitching if needed
        processFrameForStitching(pixelBuffer: pixelBuffer)
    }
    
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
        
        // Perform stitching on main thread
        Task { @MainActor in
            stitchNewFrame(uiImage)
        }
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
    func navigateToVideo() {
        Router.shared.navigateTo(.videoRecord)
    }

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
        guard let device = session.inputs.first as? AVCaptureDeviceInput else { return }
        let cameraDevice = device.device

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
        stopRecordingTimer()
        await stopCameraSession()
        
        // Reset all state
        isRecording = false
        showPlayerView = false
        showRecordingTitle = false
        stitchedImage = nil
        progressImage = nil
        errorMessage = nil
        recordingDuration = 0.0
        zoomFactor = 1.0
        
        // Clear URLs but don't reset previewURL if it exists
        recordedURLs.removeAll()
        
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
            return "Camera or microphone not available"
        case .cannotAddInput:
            return "Cannot add camera or microphone input"
        case .cannotAddOutput:
            return "Cannot add recording output"
        case .recordingFailed(let message):
            return "Recording failed: \(message)"
        }
    }
}
