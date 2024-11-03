//
//  VideoRecordView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 14/10/24.
//

import AVKit
import SwiftUI

struct VideoRecordView: View {
    @StateObject private var videoRecordPresenter = VideoRecordPresenter.shared

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Camera View
                if videoRecordPresenter.previewURL != nil {
                    ZStack {
                        VideoPreview()
                            .environmentObject(videoRecordPresenter)

                        // ADD HERE
                        VStack {
                            if let progressImage = videoRecordPresenter.stitchedImage {
                                Image(uiImage: progressImage)
                                    .resizable()
                                    .frame(width: 300, height: 300)
                                    .background(Color.black.opacity(0.5))
                                    .cornerRadius(8)
                                    .shadow(radius: 10)
                                    .rotationEffect(.degrees(90))
                                Spacer()
                            }
                        }
                    }

                } else {
                    // CameraView when not recording
                    CameraView()
                        .environmentObject(videoRecordPresenter)
                        .ignoresSafeArea()

                    // ADD HERE
                    VStack {
                        if let progressImage = videoRecordPresenter.stitchedImage {
                            Image(uiImage: progressImage)
                                .resizable()
                                .frame(width: 300, height: 300)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(8)
                                .shadow(radius: 10)
                                .rotationEffect(.degrees(90))
                            Spacer()
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if videoRecordPresenter.isBackButtonActive() {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            videoRecordPresenter.navigateBack()
                        }) {
                            Image(systemName: "chevron.backward.circle")
                                .foregroundStyle(AppColors.slate0)
                        }
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text(videoRecordPresenter.videoRecordingTitle)
                        .foregroundStyle(AppColors.slate0)
                        .shadow(color: Color.black.opacity(0.4), radius: 2, x: 1, y: 1)
                        .font(AppTypography.s4)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("Detail information button")
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(AppColors.slate0)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    VideoRecordView()
}
