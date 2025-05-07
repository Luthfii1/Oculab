//
//  CameraPreviewComponent.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 14/10/24.
//

import AVFoundation
import AVKit
import SwiftUI

struct CameraPreviewComponent: UIViewRepresentable {
    @EnvironmentObject var videoRecordPresenter: VideoRecordPresenter
    var size: CGSize

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect(origin: .zero, size: size))

        let previewLayer = AVCaptureVideoPreviewLayer(session: videoRecordPresenter.session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // Store the preview layer in the presenter
        DispatchQueue.main.async {
            self.videoRecordPresenter.preview = previewLayer
        }

        // Add pinch gesture recognizer
        let pinchGesture = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        view.addGestureRecognizer(pinchGesture)

        // Starting session
        DispatchQueue.global(qos: .background).async {
            self.videoRecordPresenter.session.startRunning()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update the preview layer's frame if needed
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        let parent: CameraPreviewComponent
        var startZoom: CGFloat = 1.0

        init(_ parent: CameraPreviewComponent) {
            self.parent = parent
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began:
                startZoom = parent.videoRecordPresenter.zoomFactor
            case .changed:
                let newScaleFactor = startZoom * gesture.scale
                parent.videoRecordPresenter.updateZoom(factor: newScaleFactor)
            default:
                break
            }
        }
    }
}

struct VideoPlayerView: View {
    @State private var player = AVPlayer()

    var body: some View {
        VideoPlayer(player: player)
            .edgesIgnoringSafeArea(.all)
            .navigationBarBackButtonHidden()
            .onAppear {
                let url = URL(string: "https://is3.cloudhost.id/oculab-fov/DummyStitch.mp4")!

                player = AVPlayer(url: url)
                player.play()
            }
            .onDisappear {
                player.pause()
            }
    }
}

struct CustomVideoPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false // Hide controls
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
