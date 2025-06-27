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

class VideoRecordPresenter: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate,
    AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate
{
    static let shared = VideoRecordPresenter(interactor: VideoInteractor())

    private let interactor: VideoInteractor

    init(interactor: VideoInteractor) {
        self.interactor = interactor
    }

    @Published var session = AVCaptureSession()
    @Published var videoRecordingTitle: String = "Sediaan: -"
    @Published var alert = false
    @Published var output = AVCaptureMovieFileOutput()
    @Published var preview: AVCaptureVideoPreviewLayer!
    @Published var hasTaken: Bool = false
    @Published var isRecording: Bool = false
    @Published var showPlayerView: Bool = false
    @Published var recordedURLs: [URL] = []
    @Published var previewURL: URL?
    @Published var showPreview: Bool = false
    @Published var stitchedImage: UIImage? // For stitched images
    @Published var progressImage: UIImage?
    @Published var progressImageChecker: String = ""
    @Published var zoomFactor: CGFloat = 1.0

    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var lastStitchTime: Date?
    private let stitchInterval: TimeInterval = Stitch.clippingDuration
    private let minZoomFactor: CGFloat = 1.0
    private let maxZoomFactor: CGFloat = 4.9

    let preRecordingInstructions: [String] = [
        "Gunakan lensa objektif 10x untuk menentukan fokus, kemudian teteskan minyak imersi",
        "Pastikan lensa objektif telah diatur ke perbesaran 100x setelah fokus ditemukan",
        "Pasang perangkat Anda dengan lensa kamera menempel pada lensa okuler",
        "Pastikan Anda berada di lokasi dengan jaringan yang lancar"
    ]
    let duringRecordingInstructions: [String] = [
        "Pastikan sediaan tetap terlihat di layar dan selalu dalam fokus optimal",
        "Baca sediaan mulai dari ujung kiri ke ujung kanan mengikuti skema pemindaian untuk pemeriksaan apusan",
        "Progress pengambilan gambar keseluruhan akan terlihat di kanan atas"
    ]

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { status in
                if status { self.setUp() }
            }
        case .denied:
            alert.toggle()
        default:
            return
        }
    }

    func setUp() {
        DispatchQueue.main.async {
            self.session.beginConfiguration()

            guard let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: cameraDevice),
                  let audioDevice = AVCaptureDevice.default(for: .audio),
                  let audioInput = try? AVCaptureDeviceInput(device: audioDevice)
            else {
                print("Error setting up camera inputs")
                return
            }

            for input in self.session.inputs {
                self.session.removeInput(input)
            }
            for output in self.session.outputs {
                self.session.removeOutput(output)
            }

            if self.session.canAddInput(videoInput) { self.session.addInput(videoInput) }
            if self.session.canAddInput(audioInput) { self.session.addInput(audioInput) }

            if self.session.canAddOutput(self.output) { self.session.addOutput(self.output) }

            self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoFrameQueue"))
            if self.session.canAddOutput(self.videoDataOutput) { self.session.addOutput(self.videoDataOutput) }

            // Configure zoom
            do {
                try cameraDevice.lockForConfiguration()
                cameraDevice.videoZoomFactor = self.zoomFactor
                cameraDevice.unlockForConfiguration()
            } catch {
                print("Error setting zoom: \(error.localizedDescription)")
            }

            self.session.commitConfiguration()

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                if !self.session.isRunning {
                    self.session.startRunning()
                    print("AVCaptureSession started.")
                }
            }
        }
    }

    func stopCameraSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                print("AVCaptureSession stopped.")
            }
        }
    }

    func startRecording() {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(Date()).mov")
        output.startRecording(to: tempURL, recordingDelegate: self)
        isRecording = true
    }

    func stopRecording() {
        output.stopRecording()
        isRecording = false
    }

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        if let error = error {
            print("VideoRecordPresenter: Recording error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.previewURL = nil
            }
            return
        }

        DispatchQueue.main.async {
            self.previewURL = outputFileURL
            print("VideoRecordPresenter: Recording finished. previewURL set to: \(outputFileURL.lastPathComponent)")
            self.stopCameraSession()
        }
    }

//    func fileOutput(
//        _ output: AVCaptureFileOutput,
//        didFinishRecordingTo outputFileURL: URL,
//        from connections: [AVCaptureConnection],
//        error: Error?
//    ) {
//        if let error = error {
//            print("Recording error: \(error.localizedDescription)")
//            return
//        }
//
//        previewURL = outputFileURL
//    }
//
    func handleButtonRecording() {
        isRecording ? stopRecording() : startRecording()
    }

//    func captureOutput(
//        _ output: AVCaptureOutput,
//        didOutput sampleBuffer: CMSampleBuffer,
//        from connection: AVCaptureConnection
//    ) {
//        if isRecording {
//            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
//                return
//            }
//
//            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
//            guard let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else {
//                return
//            }
//            let uiImage = UIImage(cgImage: cgImage)
//
//            // Update the progress image to reflect the latest frame
//            DispatchQueue.main.async {
//                self.progressImage = uiImage
//            }
//
//            // Check if 0.5 seconds have passed since the last stitch
//            let now = Date()
//            if lastStitchTime == nil || now.timeIntervalSince(lastStitchTime!) >= stitchInterval {
//                lastStitchTime = now
//                stitchNewFrame(uiImage)
//            }
//        }
//    }

    func stitchNewFrame(_ newImage: UIImage) {
        guard let lastStitchedImage = stitchedImage else {
            // First image, set as the stitched image
            DispatchQueue.main.async {
                self.stitchedImage = newImage
            }
            return
        }

        ImageRegistration.shared.register(
            floatingImage: newImage,
            referenceImage: lastStitchedImage,
            registrationMechanism: .translational
        ) { compositedImage, _ in
            DispatchQueue.main.async {
                self.stitchedImage = compositedImage
            }
        }
    }

    func getIconButtonRecording() -> String {
        return isRecording ? "circle.fill" : "button.programmable"
    }

    func getColorButtonRecording() -> Color {
        return isRecording ? .red : .white
    }

    func navigateToVideo() {
        Router.shared.navigateTo(.videoRecord)
    }

    func navigateBack() {
        Router.shared.navigateBack()
    }

    func isBackButtonActive() -> Bool {
        return previewURL == nil && !isRecording
    }

    func saveVideoToPhotos() {
        guard let videoURL = previewURL else {
            print("No video URL to save")
            return
        }

        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                }) { success, error in
                    if success {
                        Router.shared.popToRoot()
                        print("Video saved successfully!")
                    } else if let error = error {
                        print("Error saving video: \(error.localizedDescription)")
                    }
                }
            } else {
                print("Access to Photos library denied or restricted.")
            }
        }
    }

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
            print("Error setting zoom: \(error.localizedDescription)")
        }
    }
}
