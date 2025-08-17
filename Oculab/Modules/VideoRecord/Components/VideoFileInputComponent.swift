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
    @Environment(\.dismiss) private var dismiss

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
        VStack(alignment: .leading, spacing: 8) {
            // Title with required indicator
            titleSection
            
            // Video content area
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
        .alert("Video Error", isPresented: $showVideoErrorAlert) {
            Button("OK") { 
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
                .foregroundColor(AppColors.slate900)

            if isRequired {
                Text(AppValue.required)
                    .font(AppTypography.h4)
                    .foregroundColor(.red)
            }
        }
    }
    
    private var videoContentArea: some View {
        VStack(alignment: .center, spacing: 16) {
            if isLoadingVideo {
                loadingView
            } else if let url = selectedURL {
                videoPreviewSection(url: url)
            } else {
                emptyVideoSection
            }
        }
        .frame(maxWidth: .infinity, minHeight: 250)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    style: StrokeStyle(
                        lineWidth: 2,
                        dash: selectedURL == nil ? [10] : []
                    )
                )
                .foregroundColor(selectedURL == nil ? AppColors.slate100 : AppColors.purple500)
        )
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading video...")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private func videoPreviewSection(url: URL) -> some View {
        VStack(spacing: 16) {
            // Disabled video preview with tap to play full screen
            ZStack {
                // Disabled video player (black background)
                Rectangle()
                    .fill(Color.black)
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(8)
                
                // Play button overlay
                Button(action: {
                    showFullScreenPlayer = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                        
                        Text("Tap to play video")
                            .font(.caption)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                }
            }
            .onTapGesture {
                showFullScreenPlayer = true
            }
            
            // Video metadata
            if let metadata = videoMetadata {
                videoMetadataView(metadata)
            }
            
            // Action buttons (only show when not in full screen)
            if !showFullScreenPlayer {
                videoActionButtons
            }
        }
    }
    
    private func videoMetadataView(_ metadata: VideoMetadata) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text("Video Information")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("File: \(metadata.fileName)")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Text("Size: \(metadata.formattedFileSize)")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                if let duration = metadata.duration {
                    Text("Duration: \(formatDuration(duration))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var videoActionButtons: some View {
        HStack(spacing: 12) {
            // Retake video button
            AppButton(
                title: "Retake",
                leftIcon: AppText.SystemIcon.refresh,
                colorType: .secondary,
                size: .small
            ) {
                rerecordVideo()
            }
        }
    }
    
    private var emptyVideoSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No video recorded yet")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Tap the button below to start recording")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            AppButton(
                title: AppAction.create(AppTextVideoRecordCompInput.createVideoButton),
                leftIcon: AppText.SystemIcon.camera,
                colorType: .secondary,
                size: .small
            ) {
                handleCreateVideoTap()
            }
        }
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
    
    private func saveVideo() {
        Logger.info("Save video button tapped - navigating back to examination", category: .videoRecord)
        
        // Save the current video URL to exam presenter if needed
        if let url = selectedURL {
            examPresenter.recordVideo = url
            Logger.info("Video saved: \(url.lastPathComponent)", category: .videoRecord)
        }
        
        // Navigate back to examination (dismiss current view)
        dismiss()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    VideoInput(
        title: "Examination Video",
        isRequired: true,
        isEmpty: true,
        showOnboardingGuidelines: .constant(false),
        didFinishOnboarding: .constant(false),
        selectedURL: .constant(nil)
    )
    .environmentObject(DependencyInjection.shared.createExamDataPresenter())
}
