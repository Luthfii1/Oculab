//
//  VideoPreview.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 15/10/24.
//

import AVKit
import SwiftUI

struct VideoPreview: View {
    @EnvironmentObject private var videoRecordPresenter: VideoRecordPresenter

    var body: some View {
        ZStack {
            if let url = videoRecordPresenter.previewURL {
                VideoPlayer(player: AVPlayer(url: url))
                    .ignoresSafeArea()
            }

            // Control buttons (Retake & Save) at the bottom
            VStack(alignment: .center, spacing: Decimal.d16) {
                // Button to save video
                AppButton(
                    title: "Simpan Video",
                    rightIcon: "checkmark",
                    colorType: .neutral(.primary),
                    size: .large,
                    cornerRadius: 8
                ) {
                    videoRecordPresenter.navigateBack()
                }

                // Button to retake video
                AppButton(
                    title: "Ambil Ulang",
                    leftIcon: "arrow.counterclockwise",
                    colorType: .neutral(.secondary),
                    size: .large
                ) {
                    videoRecordPresenter.previewURL = nil
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 52)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    let videoRecordPresenter = VideoRecordPresenter.shared

    VideoPreview()
        .environmentObject(videoRecordPresenter)
}
