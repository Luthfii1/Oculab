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
AVCaptureFileOutputRecordingDelegate {
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
        // check camera got permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { status in
                if status {
                    self.setUp()
                }
            }
        case .denied:
            alert.toggle()
            return
        default:
            return
        }
    }

    func setUp() {
        do {
            session.beginConfiguration()

            let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            let videoInput = try AVCaptureDeviceInput(device: cameraDevice!)
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioInput = try AVCaptureDeviceInput(device: audioDevice!)

            // checking and adding to session....
            if session.canAddInput(videoInput) && session.canAddInput(audioInput) {
                session.addInput(videoInput)
                session.addInput(audioInput)
            }

            // same for output....
            if session.canAddOutput(output) {
                session.addOutput(output)
            }

            session.commitConfiguration()
        } catch {
            print(error.localizedDescription)
        }
    }

    func startRecording() {
        let tempURL = NSTemporaryDirectory() + "\(Date()).mov"
        output.startRecording(to: URL(filePath: tempURL), recordingDelegate: self)
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
            print(error.localizedDescription)
            return
        }

        print(outputFileURL)
        previewURL = outputFileURL
    }

    func handleButtonRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
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

        // Request authorization to save to Photos library
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                // Perform the changes to save the video
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
            case .denied, .restricted:
                print("Access to Photos library denied or restricted.")
            case .notDetermined:
                print("Photo library access has not been determined.")
            case .limited:
                print("Photo library just limited to some photos")
            @unknown default:
                break
            }
        }
    }
}
