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
            // Video Player in the background
            if let url = videoRecordPresenter.previewURL {
                VideoPlayer(player: AVPlayer(url: url))
                    .ignoresSafeArea() // Make sure it fills the entire screen
            }

            // Top navigation with back button, center text, and question mark icon
            VStack {
                HStack {
                    Button(action: {
                        videoRecordPresenter.previewURL = nil
                    }) {
                        Image(systemName: "chevron.left.circle")
                            .foregroundColor(.white)
                            .font(.title2)
                    }

                    Spacer()

                    Text("Video Preview")
                        .foregroundColor(.white)
                        .font(.headline)

                    Spacer()

                    Button(action: {
                        // TODO: Handle action for question mark button
                    }) {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
                .padding()
//                .background(Color.black.opacity(0.6))

                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 48)

            // Control buttons (Retake & Save) at the bottom
            HStack {
                // Button to retake video
                Button {
                    print("Ambil Ulang")
                } label: {
                    HStack(alignment: .center, spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)

                        Text("Ambil Ulang")
                            .foregroundColor(.white)
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Button to save video
                Button {
                    print("Save video")
                } label: {
                    Text("Simpan Video")
                        .foregroundColor(.black)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
}

#Preview {
    VideoPreview()
        .environmentObject(VideoRecordPresenter())
}
