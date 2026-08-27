//
//  VideoInput.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import AVKit
import SwiftUI

struct VideoInput: View {
    let videoPresenter = VideoRecordSession.current
    @EnvironmentObject var examPresenter: ExamDataPresenter

    var title: String
    var isRequired: Bool
    var isEmpty: Bool
    @Binding var showOnboardingGuidelines: Bool
    @Binding var didFinishOnboarding: Bool
    @Binding var selectedURL: URL?

    @State private var showFullScreenPlayer = false
    @State private var showVideoErrorAlert = false
    @State private var videoMetadata: VideoMetadata?
    @State private var isLoadingVideo = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !title.isEmpty {
                titleSection
            }

            videoContentArea
                .onAppear(perform: selectFile)
                .onChange(of: didFinishOnboarding) { _, newValue in
                    if newValue {
                        handleOnboardingCompletion()
                    }
                }
                .onChange(of: videoPresenter.previewURL) { _, newURL in
                    updateSelectedURL(newURL)
                }
        }
        .sheet(isPresented: $showFullScreenPlayer) {
            if let url = selectedURL {
                FullScreenVideoPlayerView(videoURL: url) {
                    showFullScreenPlayer = false
                }
            }
        }
        .alert(AppTextVideoRecordCompInput.videoErrorAlertTitle, isPresented: $showVideoErrorAlert) {
            Button(AppAction.ok) {
                showVideoErrorAlert = false
            }
        } message: {
            Text(AppTextVideoRecordCompInput.videoErrorAlertMessage)
        }
    }

    // MARK: - Subviews

    private var titleSection: some View {
        HStack(spacing: 2) {
            Text(title)
                .font(AppTypography.s4_1)
                .foregroundStyle(AppColors.slate900)

            if isRequired {
                Text(AppValue.required)
                    .font(AppTypography.h4)
                    .foregroundStyle(AppColors.red500)
            }
        }
    }

    private var videoContentArea: some View {
        VStack(spacing: 12) {
            if isLoadingVideo {
                loadingView
            } else if let url = selectedURL {
                videoPreviewSection(url: url)
            } else {
                emptyVideoSection
            }
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding(14)
        .background(AppColors.purple50.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    selectedURL == nil ? AppColors.purple200 : AppColors.purple300,
                    style: StrokeStyle(
                        lineWidth: 1,
                        dash: selectedURL == nil ? [8, 6] : []
                    )
                )
        )
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(AppTextVideoRecordCompInput.loadingMessage)
                .font(AppTypography.p3)
                .foregroundStyle(AppColors.slate400)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
    }

    private func videoPreviewSection(url: URL) -> some View {
        VStack(spacing: 14) {
            thumbnailPreview(url: url)

            if let metadata = videoMetadata {
                metadataRow(metadata)
            }

            Text(AppTextVideoRecordCompInput.tapThumbnailHint)
                .font(AppTypography.p5)
                .foregroundStyle(AppColors.slate400)
                .frame(maxWidth: .infinity)

            videoActionButtons
        }
    }

    private func thumbnailPreview(url: URL) -> some View {
        ZStack {
            VideoThumbnailView(url: url, aspectRatio: 16 / 9, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.28))

            VStack(spacing: 6) {
                Image(systemName: AppIcon.playCircle)
                    .font(.system(size: 44))
                    .foregroundStyle(AppColors.slate0)
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)

                Text(AppTextVideoRecordCompInput.playButton)
                    .font(AppTypography.p5)
                    .foregroundStyle(AppColors.slate0)
            }
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture {
            showFullScreenPlayer = true
        }
        .accessibilityLabel(AppTextVideoRecordCompInput.playButton)
        .accessibilityAddTraits(.isButton)
    }

    private func metadataRow(_ metadata: VideoMetadata) -> some View {
        HStack(spacing: 8) {
            if let duration = metadata.duration {
                metadataChip(
                    icon: AppIcon.clockFill,
                    text: String(
                        format: AppTextVideoRecordCompInput.durationLabel,
                        formatDuration(duration)
                    )
                )
            }
            metadataChip(
                icon: AppIcon.document,
                text: String(
                    format: AppTextVideoRecordCompInput.fileSizeLabel,
                    metadata.formattedFileSize
                )
            )
            Spacer(minLength: 0)
        }
    }

    private func metadataChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(AppColors.purple600)
            Text(text)
                .font(AppTypography.p5)
                .foregroundStyle(AppColors.slate600)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppColors.slate0)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(AppColors.purple100, lineWidth: 1)
        )
    }

    private var videoActionButtons: some View {
        HStack(spacing: 10) {
            AppButton(
                title: AppTextVideoRecordCompInput.playButton,
                leftIcon: AppIcon.playCircle,
                colorType: .primary,
                size: .small
            ) {
                showFullScreenPlayer = true
            }
            .frame(maxWidth: .infinity)

            AppButton(
                title: AppTextVideoRecordCompInput.retakeButton,
                leftIcon: AppIcon.refresh,
                colorType: .secondary,
                size: .small
            ) {
                rerecordVideo()
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var emptyVideoSection: some View {
        VStack(spacing: 14) {
            Image(systemName: "video.badge.plus")
                .font(.system(size: 36))
                .foregroundStyle(AppColors.purple500)

            Text(AppTextVideoRecordCompInput.emptyTitle)
                .font(AppTypography.s4_1)
                .foregroundStyle(AppColors.slate900)
                .multilineTextAlignment(.center)

            Text(AppTextVideoRecordCompInput.emptySubtitle)
                .font(AppTypography.p3)
                .foregroundStyle(AppColors.slate400)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)

            AppButton(
                title: AppTextVideoRecordCompInput.createVideoButton,
                leftIcon: AppIcon.cameraFill,
                colorType: .primary,
                size: .small
            ) {
                handleCreateVideoTap()
            }
            .frame(maxWidth: 260)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
    }

    // MARK: - Methods

    private func selectFile() {
        selectedURL = videoPresenter.previewURL

        if let url = selectedURL {
            Logger.info("VideoInput: Found URL: \(url.lastPathComponent)", category: .videoRecord)
            loadVideoMetadata(for: url)
        } else {
            Logger.info("VideoInput: No URL found in presenter", category: .videoRecord)
            videoMetadata = nil
        }
    }

    private func handleOnboardingCompletion() {
        selectFile()
        clearVideoState()
        examPresenter.newVideoRecord()
    }

    private func updateSelectedURL(_ newURL: URL?) {
        selectedURL = newURL

        if let url = newURL {
            loadVideoMetadata(for: url)
        } else {
            videoMetadata = nil
        }
    }

    private func handleCreateVideoTap() {
        if !UserDefaults.standard.bool(forKey: UserDefaultType.hasSeenOnboarding.rawValue) {
            showOnboardingGuidelines = true
            UserDefaults.standard.set(true, forKey: UserDefaultType.hasSeenOnboarding.rawValue)
        } else {
            clearVideoState()
            examPresenter.newVideoRecord()
        }
    }

    private func clearVideoState() {
        videoPresenter.previewURL = nil
        examPresenter.recordVideo = nil
        videoMetadata = nil
        Logger.info("VideoInput: Video state cleared", category: .videoRecord)
    }

    private func loadVideoMetadata(for url: URL) {
        isLoadingVideo = true

        Task {
            let interactor = VideoInteractor()
            let metadata = interactor.getVideoMetadata(at: url)

            await MainActor.run {
                self.videoMetadata = metadata
                self.isLoadingVideo = false
            }
        }
    }

    private func rerecordVideo() {
        clearVideoState()
        examPresenter.newVideoRecord()
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    VideoInput(
        title: AppValue.empty,
        isRequired: false,
        isEmpty: true,
        showOnboardingGuidelines: .constant(false),
        didFinishOnboarding: .constant(false),
        selectedURL: .constant(nil)
    )
    .environmentObject(DependencyInjection.shared.createExamDataPresenter())
    .padding()
}
