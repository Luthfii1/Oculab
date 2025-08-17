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
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var showingFullScreen = false
    @State private var duration: Double = 0
    @State private var isSaving = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            // Video thumbnail preview
            if let url = videoRecordPresenter.previewURL {
                VideoThumbnailView(url: url)
                    .onAppear {
                        setupPlayer(with: url)
                    }
            } else {
                // Fallback content
                Rectangle()
                    .fill(Color.black)
                    .ignoresSafeArea()
                    .overlay(
                        VStack {
                            Image(systemName: "video.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No video available")
                                .foregroundColor(.gray)
                                .font(.headline)
                        }
                    )
            }

            // Control overlay
            VStack {
                Spacer()
                
                // Video information
                if duration > 0 {
                    videoInfoOverlay
                        .padding(.horizontal, 20)
                }
                
                // Control buttons - always show since video is static
                controlButtonsOverlay
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
            }
        }
        .background(Color.black)
        .ignoresSafeArea(.container, edges: .top)
        .sheet(isPresented: $showingFullScreen) {
            if let url = videoRecordPresenter.previewURL {
                FullScreenVideoPlayerView(videoURL: url) {
                    showingFullScreen = false
                }
            }
        }
    }
    
    // MARK: - Subviews
    private var videoInfoOverlay: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Duration: \(formatTime(duration))")
                    .font(.caption)
                    .foregroundColor(.white)
                
                if let url = videoRecordPresenter.previewURL {
                    Text("Size: \(getFileSize(url))")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.6))
            .cornerRadius(8)
            
            Spacer()
            
            // Playback control - opens full screen player
            Button(action: {
                showingFullScreen = true
            }) {
                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
        }
        .padding(.bottom, 16)
    }
    
    private var controlButtonsOverlay: some View {
        VStack(alignment: .center, spacing: 16) {
            // Primary action - Save video
            AppButton(
                title: isSaving ? "Saving..." : AppTextVideoRecordCompPreview.saveVideoButton,
                rightIcon: AppText.SystemIcon.success,
                colorType: .neutral(.primary),
                size: .large,
                cornerRadius: 8,
                isEnabled: !videoRecordPresenter.isLoading && !isSaving
            ) {
                guard !isSaving else { return }
                
                Task {
                    isSaving = true
                    await videoRecordPresenter.saveVideoWithoutNavigation()
                    await videoRecordPresenter.cleanup()
                    
                    // Use router navigation to go back one level
                    await MainActor.run {
                        isSaving = false
                        videoRecordPresenter.navigateBack()
                    }
                }
            }

            // Secondary action - Retake video
            AppButton(
                title: AppTextVideoRecordCompPreview.retakeVideoButton,
                leftIcon: AppText.SystemIcon.refresh,
                colorType: .neutral(.secondary),
                size: .large,
                cornerRadius: 8,
                isEnabled: !videoRecordPresenter.isLoading
            ) {
                retakeVideo()
            }
        }
    }
    
    // MARK: - Methods
    private func setupPlayer(with url: URL) {
        // Only used for getting duration and metadata
        player = AVPlayer(url: url)
        
        // Get duration
        let asset = AVAsset(url: url)
        Task {
            do {
                let duration = try await asset.load(.duration)
                await MainActor.run {
                    self.duration = CMTimeGetSeconds(duration)
                }
            } catch {
                Logger.error("Failed to load video duration: \(error)", category: .videoRecord)
            }
        }
    }
    
    private func retakeVideo() {
        // Clean up current video
        player?.pause()
        player = nil
        
        // Delete temporary file
        if let url = videoRecordPresenter.previewURL {
            deleteTemporaryFile(at: url)
        }
        
        // Reset presenter state
        videoRecordPresenter.previewURL = nil
        videoRecordPresenter.stitchedImage = nil
        
        Logger.info("Video retake initiated", category: .videoRecord)
    }
    
    private func shareVideo() {
        guard let url = videoRecordPresenter.previewURL else { return }
        
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
    
    private func deleteVideo() {
        guard let url = videoRecordPresenter.previewURL else { return }
        
        deleteTemporaryFile(at: url)
        videoRecordPresenter.previewURL = nil
        videoRecordPresenter.navigateBack()
    }
    
    private func deleteTemporaryFile(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            Logger.info("Temporary video file deleted: \(url.lastPathComponent)", category: .videoRecord)
        } catch {
            Logger.error("Failed to delete temporary file: \(error.localizedDescription)", category: .videoRecord)
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func getFileSize(_ url: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
                formatter.countStyle = .file
                return formatter.string(fromByteCount: fileSize)
            }
        } catch {
            Logger.error("Failed to get file size: \(error.localizedDescription)", category: .videoRecord)
        }
        return "Unknown"
    }
}

#Preview {
    let videoRecordPresenter = VideoRecordPresenter.shared
    VideoPreview()
        .environmentObject(videoRecordPresenter)
}

// MARK: - Video Thumbnail View
struct VideoThumbnailView: View {
    let url: URL
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        ZStack {
            if let image = thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                // Loading placeholder
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Loading preview...")
                        .foregroundColor(.white)
                        .font(.caption)
                }
            }
        }
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        Task {
            let thumbnail = await createVideoThumbnail(from: url)
            await MainActor.run {
                self.thumbnailImage = thumbnail
            }
        }
    }
    
    private func createVideoThumbnail(from url: URL) async -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.requestedTimeToleranceBefore = .zero
        
        do {
            let time = CMTime(seconds: 0, preferredTimescale: 600)
            let cgImage = try await imageGenerator.image(at: time).image
            return UIImage(cgImage: cgImage)
        } catch {
            Logger.error("Failed to generate video thumbnail: \(error)", category: .videoRecord)
            return nil
        }
    }
}
