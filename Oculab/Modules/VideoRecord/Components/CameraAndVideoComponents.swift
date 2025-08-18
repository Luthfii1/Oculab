//
//  CameraAndVideoComponents.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 14/10/24.
//

import AVFoundation
import AVKit
import SwiftUI
import Combine

// MARK: - Camera Preview Component
struct CameraPreviewComponent: UIViewRepresentable {
    @EnvironmentObject var videoRecordPresenter: VideoRecordPresenter
    var size: CGSize

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect(origin: .zero, size: size))
        view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer(session: videoRecordPresenter.session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // Store the preview layer in the presenter
        DispatchQueue.main.async {
            self.videoRecordPresenter.preview = previewLayer
        }

        // Add gesture recognizers
        addGestureRecognizers(to: view, context: context)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update the preview layer's frame if needed
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> CameraPreviewCoordinator {
        CameraPreviewCoordinator(self)
    }
    
    private func addGestureRecognizers(to view: UIView, context: Context) {
        // Pinch gesture for zoom
        let pinchGesture = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(CameraPreviewCoordinator.handlePinch(_:))
        )
        view.addGestureRecognizer(pinchGesture)
        
        // Tap gesture for focus
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(CameraPreviewCoordinator.handleTap(_:))
        )
        view.addGestureRecognizer(tapGesture)
        
        // Double tap for auto zoom
        let doubleTapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(CameraPreviewCoordinator.handleDoubleTap(_:))
        )
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)
        
        // Ensure single tap doesn't interfere with double tap
        tapGesture.require(toFail: doubleTapGesture)
    }
}

// MARK: - Camera Preview Coordinator
class CameraPreviewCoordinator: NSObject {
    let parent: CameraPreviewComponent
    var startZoom: CGFloat = 1.0

    init(_ parent: CameraPreviewComponent) {
        self.parent = parent
    }

    @MainActor
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            startZoom = parent.videoRecordPresenter.zoomFactor
        case .changed:
            let newScaleFactor = startZoom * gesture.scale
            Task { @MainActor in
                parent.videoRecordPresenter.updateZoom(factor: newScaleFactor)
            }
        default:
            break
        }
    }
    
    @MainActor
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let tapPoint = gesture.location(in: gesture.view)
        guard let view = gesture.view else { return }
        
        // Convert tap point to camera coordinate system
        let devicePoint = CGPoint(
            x: tapPoint.y / view.bounds.height,
            y: 1.0 - (tapPoint.x / view.bounds.width)
        )
        
        focusCamera(at: devicePoint)
    }
    
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        Task { @MainActor in
            let currentZoom = parent.videoRecordPresenter.zoomFactor
            let targetZoom: CGFloat = currentZoom > 1.5 ? 1.0 : 3.0
            
            parent.videoRecordPresenter.updateZoom(factor: targetZoom)
        }
    }
    
    @MainActor
    private func focusCamera(at point: CGPoint) {
        guard let device = parent.videoRecordPresenter.session.inputs.first as? AVCaptureDeviceInput else {
            return
        }
        
        let cameraDevice = device.device
        
        do {
            try cameraDevice.lockForConfiguration()
            
            // Set focus point
            if cameraDevice.isFocusPointOfInterestSupported &&
               cameraDevice.isFocusModeSupported(.autoFocus) {
                cameraDevice.focusPointOfInterest = point
                cameraDevice.focusMode = .autoFocus
            }
            
            // Set exposure point
            if cameraDevice.isExposurePointOfInterestSupported &&
               cameraDevice.isExposureModeSupported(.autoExpose) {
                cameraDevice.exposurePointOfInterest = point
                cameraDevice.exposureMode = .autoExpose
            }
            
            cameraDevice.unlockForConfiguration()
            
            Logger.info("Camera focused at point: \(point)", category: .videoRecord)
            
        } catch {
            Logger.error("Failed to focus camera: \(error.localizedDescription)", category: .videoRecord)
        }
    }
}

// MARK: - Simple Video Player Component
struct SimpleVideoPlayerComponent: View {
    @State private var player = AVPlayer()
    @State private var isLoading = true
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        ZStack {
            VideoPlayer(player: player)
                .onAppear {
                    setupPlayer()
                }
                .onDisappear {
                    player.pause()
                }
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            }
        }
        .background(Color.black)
        .cornerRadius(8)
    }
    
    private func setupPlayer() {
        guard let url = URL(string: "https://is3.cloudhost.id/oculab-fov/DummyStitch.mp4") else {
            Logger.error("Invalid video URL", category: .videoRecord)
            return
        }
        
        player = AVPlayer(url: url)
        
        // Monitor player status
        player.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { status in
                switch status {
                case .readyToPlay:
                    isLoading = false
                    player.play()
                case .failed:
                    Logger.error("Video player failed to load", category: .videoRecord)
                    isLoading = false
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Custom Video Player Component
struct CustomVideoPlayerComponent: UIViewControllerRepresentable {
    let player: AVPlayer
    let showsPlaybackControls: Bool

    init(player: AVPlayer, showsPlaybackControls: Bool = false) {
        self.player = player
        self.showsPlaybackControls = showsPlaybackControls
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = showsPlaybackControls
        controller.videoGravity = .resizeAspectFill
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Backward Compatibility Aliases
// These maintain compatibility with existing code
typealias VideoPlayerView = SimpleVideoPlayerComponent
typealias CustomVideoPlayerView = CustomVideoPlayerComponent
