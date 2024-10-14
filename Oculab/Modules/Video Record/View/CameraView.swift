//
//  CameraView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 14/10/24.
//

import AVFoundation
import SwiftUI

struct CameraView: View {
    @EnvironmentObject var videoRecordPresenter: VideoRecordPresenter

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            CameraPreviewComponent(size: size)
                .environmentObject(videoRecordPresenter)
        }
        .onAppear {
            videoRecordPresenter.checkPermission()
        }
        .alert(isPresented: $videoRecordPresenter.alert) {
            Alert(
                title: Text("Camera Access"),
                message: Text("Please enable camera and microphone access in settings"),
                primaryButton: .default(Text("Settings")) {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                },
                secondaryButton: .cancel()
            )
        }
    }
}

#Preview {
    CameraView()
}
