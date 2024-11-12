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
AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
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
    @Published var recordedURLs: [URL] = []
    @Published var previewURL: URL?
    @Published var showPreview: Bool = false
    @Published var stitchedImage: UIImage? // For stitched images
    @Published var progressImage: UIImage?
    @Published var progressImageChecker: String = ""

    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var lastStitchTime: Date?
    private let stitchInterval: TimeInterval = Stitch.clippingDuration

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
        session.beginConfiguration()

        guard let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: cameraDevice),
              let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice)
        else {
            print("Error setting up camera inputs")
            return
        }

        if session.canAddInput(videoInput) { session.addInput(videoInput) }
        if session.canAddInput(audioInput) { session.addInput(audioInput) }

        // Set up the movie output
        if session.canAddOutput(output) { session.addOutput(output) }

        // Set up the video data output for frame extraction
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoFrameQueue"))
        if session.canAddOutput(videoDataOutput) { session.addOutput(videoDataOutput) }

        session.commitConfiguration()

        session.startRunning()
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
            print("Recording error: \(error.localizedDescription)")
            return
        }

        previewURL = outputFileURL
    }

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
}
