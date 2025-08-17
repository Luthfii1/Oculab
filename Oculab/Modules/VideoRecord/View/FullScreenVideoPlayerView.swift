//
//  FullScreenVideoPlayerView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 17/08/25.
//

import SwiftUI

// MARK: - Full Screen Video Player View
struct FullScreenVideoPlayerView: View {
    let videoURL: URL
    var onClose: () -> Void
    
    @StateObject private var playerManager: VideoPlayerManager
    
    // MARK: - Initialization
    init(videoURL: URL, onClose: @escaping () -> Void) {
        self.videoURL = videoURL
        self.onClose = onClose
        self._playerManager = StateObject(wrappedValue: VideoPlayerManager(videoURL: videoURL))
    }
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            // Content based on state
            if playerManager.hasError {
                VideoPlayerErrorView(onClose: onClose)
            } else if playerManager.isLoading {
                VideoPlayerLoadingView()
            } else {
                // Video player content
                videoPlayerContent
            }
        }
        .onAppear {
            Logger.info("🎬 FullScreenVideoPlayerView appeared", category: .videoRecord)
            Logger.info("🎬 Video URL: \(videoURL)", category: .videoRecord)
            Logger.info("🎬 Video path exists: \(FileManager.default.fileExists(atPath: videoURL.path))", category: .videoRecord)
            playerManager.setupPlayer()
        }
        .onDisappear {
            playerManager.cleanup()
        }
        .statusBarHidden()
    }
    
    // MARK: - Video Player Content
    private var videoPlayerContent: some View {
        ZStack {
            // Custom video player
            if let player = playerManager.player {
                CustomVideoPlayerView(player: player)
            }
            
            // Video controls overlay
            videoControlsOverlay
        }
    }
    
    // MARK: - Video Controls Overlay
    private var videoControlsOverlay: some View {
        VStack {
            // Top controls
            VideoPlayerTopControls(
                videoURL: videoURL,
                currentPlaybackTime: playerManager.currentTime,
                totalVideoDuration: playerManager.duration,
                hasVideoReachedEnd: playerManager.hasReachedEnd,
                onClose: onClose
            )
            
            Spacer()
            
            // Bottom controls
            VideoPlayerBottomControls(
                currentPlaybackTime: playerManager.currentTime,
                totalVideoDuration: playerManager.duration,
                isUserDragging: playerManager.isDragging,
                isVideoPlaying: playerManager.isPlaying,
                hasVideoReachedEnd: playerManager.hasReachedEnd,
                onTimeChange: { time in
                    playerManager.currentTime = time
                    if !playerManager.isDragging {
                        playerManager.seekTo(time)
                    }
                },
                onDragStateChange: { isDragging in
                    playerManager.isDragging = isDragging
                    if !isDragging {
                        playerManager.seekTo(playerManager.currentTime)
                    }
                },
                onPlayPause: {
                    playerManager.togglePlayback()
                },
                onSeekBackward: {
                    playerManager.seekBy(-15)
                },
                onSeekForward: {
                    playerManager.seekBy(15)
                }
            )
        }
    }
}

// MARK: - Preview
#Preview {
    FullScreenVideoPlayerView(
        videoURL: URL(string: "https://is3.cloudhost.id/oculab-fov/DummyStitch.mp4")!
    ) {
        // Close action
    }
}
