//
//  FullScreenVideoPlayerView.swift
//  Oculab
//
//  Created by Rangga Yudhistira Brata on 24/05/25.
//

import SwiftUI
import AVKit
import AVFoundation
import Combine

struct FullScreenVideoPlayerView: View {
    let videoURL: URL
    var onClose: () -> Void
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var showControls = true
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isDragging = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var hasError = false
    @State private var isLoading = true
    @State private var hasReachedEnd = false
    
    var body: some View {
        ZStack {
            // Video player background
            Color.black
                .ignoresSafeArea()
            
            if hasError {
                // Error state
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    Text("Failed to load video")
                        .foregroundColor(.white)
                        .font(.headline)
                    Text("Please try again or contact support")
                        .foregroundColor(.gray)
                        .font(.caption)
                    
                    Button("Close") {
                        onClose()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .cornerRadius(8)
                }
            } else if isLoading {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Loading video...")
                        .foregroundColor(.white)
                        .font(.headline)
                }
            } else {
                // Custom video player without default controls
                if let player = player {
                    FullScreenCustomVideoPlayerView(player: player)
                }
            }
            
            // Custom controls overlay
            if !isLoading && !hasError {
                VStack {
                    // Top controls
                    topControlsView
                    
                    Spacer()
                    
                    // Bottom controls
                    bottomControlsView
                }
            }
        }
        .onAppear {
            Logger.info("🎬 FullScreenVideoPlayerView appeared", category: .videoRecord)
            Logger.info("🎬 Video URL: \(videoURL)", category: .videoRecord)
            Logger.info("🎬 Video path exists: \(FileManager.default.fileExists(atPath: videoURL.path))", category: .videoRecord)
            setupPlayer()
        }
        .onDisappear {
            cleanup()
        }
        .statusBarHidden()
    }
    
    // MARK: - Subviews
    private var topControlsView: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: AppText.SystemIcon.close)
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Video info
            VStack(alignment: .trailing) {
                Text(videoURL.lastPathComponent)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if duration > 0 {
                    Text(formatTime(currentTime) + " / " + formatTime(duration))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                    
                    if hasReachedEnd {
                        Text("Tap replay to watch again")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.6))
            .cornerRadius(8)
        }
        .padding()
    }
    
    private var bottomControlsView: some View {
        VStack(spacing: 12) {
            // Progress bar
            if duration > 0 {
                progressBar
            }
            
            // Control buttons
            HStack(spacing: 30) {
                // Rewind 15s
                Button(action: {
                    seekBy(-15)
                }) {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                // Play/Pause
                Button(action: {
                    togglePlayback()
                }) {
                    Image(systemName: getPlayButtonIcon())
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                
                // Forward 15s
                Button(action: {
                    seekBy(15)
                }) {
                    Image(systemName: "goforward.15")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var progressBar: some View {
        VStack(spacing: 4) {
            // Time labels
            HStack {
                Text(formatTime(currentTime))
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(formatTime(duration))
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            // Progress slider
            Slider(
                value: Binding(
                    get: { currentTime },
                    set: { newValue in
                        currentTime = newValue
                        if !isDragging {
                            seekTo(newValue)
                        }
                    }
                ),
                in: 0...duration,
                onEditingChanged: { editing in
                    isDragging = editing
                    if !editing {
                        seekTo(currentTime)
                    }
                }
            )
            .accentColor(.white)
        }
    }
    
    // MARK: - Methods
    private func getPlayButtonIcon() -> String {
        if hasReachedEnd {
            return "arrow.counterclockwise.circle.fill"  // Replay icon
        } else if isPlaying {
            return "pause.circle.fill"  // Pause icon
        } else {
            return "play.circle.fill"   // Play icon
        }
    }
    
    private func setupPlayer() {
        // Validate video file exists
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            Logger.error("Video file does not exist at path: \(videoURL.path)", category: .videoRecord)
            hasError = true
            isLoading = false
            return
        }
        
        Logger.info("Setting up video player for URL: \(videoURL.path)", category: .videoRecord)
        Logger.info("File size: \(getFileSize(videoURL))", category: .videoRecord)
        
        player = AVPlayer(url: videoURL)
        
        guard let player = player else {
            hasError = true
            isLoading = false
            return
        }
        
        // Ensure player is ready
        let playerItem = AVPlayerItem(url: videoURL)
        player.replaceCurrentItem(with: playerItem)
        
        // Load duration
        let asset = AVAsset(url: videoURL)
        Task {
            do {
                let duration = try await asset.load(.duration)
                let isPlayable = try await asset.load(.isPlayable)
                let hasVideoTracks = try await asset.loadTracks(withMediaType: .video).count > 0
                
                await MainActor.run {
                    self.duration = CMTimeGetSeconds(duration)
                    if isPlayable && hasVideoTracks {
                        self.isLoading = false
                        Logger.info("Video loaded successfully - Duration: \(self.duration)s", category: .videoRecord)
                    } else {
                        self.hasError = true
                        self.isLoading = false
                        Logger.error("Video is not playable or has no video tracks", category: .videoRecord)
                    }
                }
            } catch {
                await MainActor.run {
                    self.hasError = true
                    self.isLoading = false
                }
                Logger.error("Failed to load video asset: \(error)", category: .videoRecord)
            }
        }
        
        // Monitor playback state
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { status in
                isPlaying = (status == .playing)
                Logger.info("Player status changed to: \(status)", category: .videoRecord)
            }
            .store(in: &cancellables)
        
        // Monitor player item status
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { status in
                switch status {
                case .readyToPlay:
                    isLoading = false
                    Logger.info("Video player ready to play", category: .videoRecord)
                case .failed:
                    hasError = true
                    isLoading = false
                    Logger.error("Video player failed to load: \(playerItem.error?.localizedDescription ?? "Unknown error")", category: .videoRecord)
                case .unknown:
                    Logger.info("Video player status unknown", category: .videoRecord)
                @unknown default:
                    Logger.info("Video player status: \(status)", category: .videoRecord)
                }
            }
            .store(in: &cancellables)
        
        // Monitor current time
        player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { time in
            guard !isDragging else { return }
            let newTime = CMTimeGetSeconds(time)
            currentTime = newTime
            
            // Check if video has reached the end (within 0.1 seconds)
            if duration > 0 && abs(newTime - duration) < 0.1 {
                hasReachedEnd = true
                isPlaying = false
                Logger.info("Video reached end", category: .videoRecord)
            }
        }
        
        // Monitor for video end notification
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                hasReachedEnd = true
                isPlaying = false
                Logger.info("Video finished playing", category: .videoRecord)
            }
            .store(in: &cancellables)
        
        // Auto-play after a brief delay to ensure everything is loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if !hasError && !isLoading {
                Logger.info("Starting video playback", category: .videoRecord)
                player.play()
            }
        }
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
    
    private func cleanup() {
        player?.pause()
        player = nil
        cancellables.removeAll()
    }
    
    private func togglePlayback() {
        guard let player = player else { return }
        
        if hasReachedEnd {
            // Replay from start
            replayVideo()
        } else if isPlaying {
            player.pause()
        } else {
            player.play()
        }
    }
    
    private func replayVideo() {
        guard let player = player else { return }
        
        // Reset to beginning
        let startTime = CMTime.zero
        player.seek(to: startTime) { _ in
            DispatchQueue.main.async {
                self.hasReachedEnd = false
                self.currentTime = 0
                player.play()
                Logger.info("Video replaying from start", category: .videoRecord)
            }
        }
    }
    
    private func seekTo(_ time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
        
        // Reset end state if seeking away from end
        if hasReachedEnd && time < duration - 0.1 {
            hasReachedEnd = false
        }
    }
    
    private func seekBy(_ seconds: Double) {
        let newTime = max(0, min(duration, currentTime + seconds))
        seekTo(newTime)
    }
    
    private func formatTime(_ time: Double) -> String {
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Custom Video Player View without default controls
struct FullScreenCustomVideoPlayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerContainerView {
        let containerView = PlayerContainerView()
        containerView.backgroundColor = .black
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        containerView.layer.addSublayer(playerLayer)
        
        // Store reference in the container view
        containerView.playerLayer = playerLayer
        
        // Set initial frame
        DispatchQueue.main.async {
            playerLayer.frame = containerView.bounds
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        // Update frame when view bounds change
        DispatchQueue.main.async {
            uiView.playerLayer?.frame = uiView.bounds
        }
    }
}

// Custom container view to properly handle player layer
class PlayerContainerView: UIView {
    var playerLayer: AVPlayerLayer? {
        didSet {
            if let playerLayer = playerLayer {
                playerLayer.frame = bounds
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Ensure player layer matches view bounds
        playerLayer?.frame = bounds
    }
}

#Preview {
    FullScreenVideoPlayerView(
        videoURL: URL(string: "https://is3.cloudhost.id/oculab-fov/DummyStitch.mp4")!
    ) {
        // Close action
    }
}
