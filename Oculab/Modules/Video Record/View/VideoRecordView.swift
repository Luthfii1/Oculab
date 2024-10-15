//
//  VideoRecordView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 14/10/24.
//

import AVKit
import SwiftUI

struct VideoRecordView: View {
    @StateObject private var videoRecordPresenter = VideoRecordPresenter()

    var body: some View {
        ZStack(alignment: .bottom) {
            // Camera View
            if videoRecordPresenter.previewURL != nil {
                VideoPreview()
                    .environmentObject(videoRecordPresenter)
            } else {
                // CameraView when not recording
                CameraView()
                    .environmentObject(videoRecordPresenter)
                    .ignoresSafeArea()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    VideoRecordView()
}
