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
    @Environment(\.dismiss) var dismiss // To handle dismissing the view if needed, e.g., on permission denial.

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Camera View
                if videoRecordPresenter.previewURL != nil {
                    ZStack {
                        VideoPreview()
                            .environmentObject(videoRecordPresenter)

                        // ADD HERE
//                        VStack {
//                            ZStack {
//                                VideoPlayerView()
//                                    .frame(width: 150, height: 100)
//                                    .position(x: UIScreen.main.bounds.width - 120, y: 60) // Adjust position
//                            }
//                        }
                    }

                } else {
                    // CameraView when not recording
                    CameraView()
                        .environmentObject(videoRecordPresenter)
                        .ignoresSafeArea()

                    // ADD HERE
                    if videoRecordPresenter.isRecording && videoRecordPresenter.showPlayerView {
                        VStack {
                            ZStack {
                                VideoPlayerView()
                                    .frame(width: 187, height: 111)
                                    .border(Color.white, width: 2)
                                    .position(x: UIScreen.main.bounds.width - 120, y: 60) // Adjust position
                            }
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
                    if videoRecordPresenter.showRecordingTitle {
                        Text(videoRecordPresenter.videoRecordingTitle)
                            .foregroundStyle(AppColors.slate0)
                            .shadow(color: Color.black.opacity(0.4), radius: 2, x: 1, y: 1)
                            .font(AppTypography.s4)
                    }
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
        .onAppear {
            print("VideoRecordView appeared. Checking camera permission and setting up.")
            videoRecordPresenter.checkPermission()
        }
        .onDisappear {
            print("VideoRecordView disappeared. Stopping camera session.")
            videoRecordPresenter.stopCameraSession()

            videoRecordPresenter.isRecording = false
            videoRecordPresenter.showPlayerView = false
            videoRecordPresenter.stitchedImage = nil
            videoRecordPresenter.progressImage = nil
        }
        .alert(isPresented: $videoRecordPresenter.alert) {
            Alert(
                    title: Text(AppTextVideoRecordView.cameraAccessDeniedTitle),
                    message: Text(AppTextVideoRecordView.cameraAccessDeniedMessage),
                    primaryButton: .default(Text(AppTextVideoRecordView.goToSettingsButton)) {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    },
                    secondaryButton: .cancel(Text(AppTextVideoRecordView.cancelButton)) {
                        dismiss() 
                    }
                )
        }
    }
}

#Preview {
    VideoRecordView()
}
