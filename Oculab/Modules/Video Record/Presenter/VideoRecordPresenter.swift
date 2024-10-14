//
//  VideoRecordPresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 14/10/24.
//

import AVFoundation
import Foundation

class VideoRecordPresenter: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var session = AVCaptureSession()
    @Published var alert = false
    @Published var output = AVCaptureMovieFileOutput()
    @Published var preview: AVCaptureVideoPreviewLayer!
    @Published var hasTaken: Bool = false

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
}
