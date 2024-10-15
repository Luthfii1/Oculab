//
//  CameraPreviewComponent.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 14/10/24.
//

import AVFoundation
import SwiftUI

struct CameraPreviewComponent: UIViewRepresentable {
    @EnvironmentObject var videoRecordPresenter: VideoRecordPresenter
    var size: CGSize

    func makeUIView(context: Context) -> UIView {
        let view = UIView()

        videoRecordPresenter.preview = AVCaptureVideoPreviewLayer(session: videoRecordPresenter.session)
        videoRecordPresenter.preview.frame.size = size

        videoRecordPresenter.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(videoRecordPresenter.preview)

        // starting session
        DispatchQueue.global(qos: .background).async {
            videoRecordPresenter.session.startRunning()
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
