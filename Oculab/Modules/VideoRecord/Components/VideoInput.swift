//
//  VideoInput.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import AVKit
import SwiftUI

struct VideoInput: View {
    let videoPresenter = VideoRecordPresenter.shared
    @EnvironmentObject var examPresenter: ExamDataPresenter

    var title: String
    var isRequired: Bool
    var isEmpty: Bool
    @Binding var showOnboardingGuidelines: Bool
    @Binding var didFinishOnboarding: Bool
    @Binding var selectedURL: URL?

    @State private var showFullScreenPlayer = false
    @State private var showVideoErrorAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: Decimal.d8) {
            HStack(spacing: Decimal.d2) {
                Text(title)
                    .font(AppTypography.s4_1)
                    .foregroundColor(AppColors.slate900)

                if isRequired {
                    Text(AppValue.required)
                        .font(AppTypography.h4)
                        .foregroundColor(.red)
                }
            }

            VStack(alignment: .center) {
                if selectedURL == nil {
                    AppButton(title: AppAction.create("Gambar"), leftIcon: AppIcon.camera, colorType: .secondary, size: .small) {
                        if !UserDefaults.standard.bool(forKey: UserDefaultType.hasSeenOnboarding.rawValue) {
                            showOnboardingGuidelines = true
                            UserDefaults.standard.set(true, forKey: UserDefaultType.hasSeenOnboarding.rawValue)
                        } else {
                            videoPresenter.previewURL = nil
                            examPresenter.recordVideo = nil

                            print("VideoInput: Initiating new video record. videoPresenter.previewURL is now \(videoPresenter.previewURL?.lastPathComponent ?? "nil")")
                            print("VideoInput: examPresenter.recordVideo is now \(examPresenter.recordVideo?.lastPathComponent ?? "nil")")

                            examPresenter.newVideoRecord()
                        }
                    }

                } else {
                    VideoPlayer(player: AVPlayer(url: selectedURL!))
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                        .cornerRadius(Decimal.d8)

                    AppButton(title: AppAction.view("Video"), leftIcon: AppIcon.eye, colorType: .secondary, size: .small) {
                        // Cek apakah file masih bisa diputar
                        if let url = selectedURL, FileManager.default.fileExists(atPath: url.path) {
                            showFullScreenPlayer = true
                        } else {
                            showVideoErrorAlert = true
                        }
                    }
                }
            }
            // Alert untuk error handling
            .alert(isPresented: $showVideoErrorAlert) {
                Alert(
                    title: Text(AppState.failed("Memutar Video")),
                    message: Text(AppTextVideoRecordCompInput.videoErrorAlertMessage),
                    dismissButton: .default(Text(AppAction.ok))
                )
            }

            // Full-screen video preview overlay
            .fullScreenCover(isPresented: $showFullScreenPlayer) {
                if let url = selectedURL {
                    FullScreenVideoPlayerView(videoURL: url) {
                        showFullScreenPlayer = false
                    }
                }
            }
            .padding(.horizontal, Decimal.d16)
            .padding(.vertical, Decimal.d16)
            .frame(maxWidth: .infinity, minHeight: 250.0, alignment: .center)
            .cornerRadius(Decimal.d12)
            .overlay(
                RoundedRectangle(cornerRadius: Decimal.d12)
                    .stroke(style: StrokeStyle(
                        lineWidth: 2,
                        dash: selectedURL == nil ? [10] : []
                    ))
                    .foregroundColor(AppColors.slate100)
            )
        }
        .onAppear(perform: selectFile)
        .onChange(of: didFinishOnboarding) {
            if didFinishOnboarding {
                selectFile()
                videoPresenter.previewURL = nil
                examPresenter.newVideoRecord()
            }
        }
    }

    private func selectFile() {
        selectedURL = videoPresenter.previewURL

        if let url = selectedURL {
            print("VideoInput appeared or updated. Found URL: \(url.lastPathComponent)")
        } else {
            print("VideoInput appeared or updated. No URL found in presenter.")
        }
    }

    private func previewVideo() {
        print("Preview video at URL: \(selectedURL?.absoluteString ?? "No URL")")
    }
}
