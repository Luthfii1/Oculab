//
//  CameraView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 14/10/24.
//

import AVFoundation
import SwiftUI

struct CameraView: View {
    @StateObject private var videoRecordPresenter = VideoRecordPresenter.shared

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                CameraPreviewComponent(size: size)
                    .environmentObject(videoRecordPresenter)

                Button {
                    videoRecordPresenter.handleButtonRecording()
                } label: {
                    Image(systemName: videoRecordPresenter.getIconButtonRecording())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(videoRecordPresenter.getColorButtonRecording())
                        .frame(width: 60, height: 60)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 32)
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            Task {
                videoRecordPresenter.checkPermission()
            }
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
