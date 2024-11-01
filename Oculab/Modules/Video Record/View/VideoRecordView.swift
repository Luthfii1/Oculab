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
                // Display stitched image if available
                if let stitchedImage = videoRecordPresenter.stitchedImage {
                    Image(uiImage: stitchedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200) // Adjust frame height as needed
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                        .padding()
                        .overlay(
                            Text("Stitched Image")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8),
                            alignment: .topLeading
                        )
                }

                // Video or camera preview
                if videoRecordPresenter.previewURL != nil {
                    VideoPreview()
                        .environmentObject(videoRecordPresenter)
                } else {
                    CameraView()
                        .environmentObject(videoRecordPresenter)
                        .ignoresSafeArea()
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
                        videoRecordPresenter.navigateToStitch()
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
