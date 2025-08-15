//
//  FullScreenVideoPlayerView.swift
//  Oculab
//
//  Created by Rangga Yudhistira Brata on 24/05/25.
//

import SwiftUI
import AVKit
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
    
    var body: some View {
        ZStack {
            // Video player background
            Color.black
                .ignoresSafeArea()
            
            // Video player
            if let player = player {
                VideoPlayer(player: player)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showControls.toggle()
                        }
                    }
            }
            
            // Custom controls overlay
            if showControls {
                VStack {
                    // Top controls
                    topControlsView
                    
                    Spacer()
                    
                    // Bottom controls
                    bottomControlsView
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            setupPlayer()
            hideControlsAfterDelay()
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
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
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
    private func setupPlayer() {
        player = AVPlayer(url: videoURL)
        
        guard let player = player else { return }
        
        // Load duration
        let asset = AVAsset(url: videoURL)
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
        
        // Monitor playback state
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { status in
                isPlaying = (status == .playing)
            }
            .store(in: &cancellables)
        
        // Monitor current time
        player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { time in
            guard !isDragging else { return }
            currentTime = CMTimeGetSeconds(time)
        }
        
        // Auto-play
        player.play()
    }
    
    private func cleanup() {
        player?.pause()
        player = nil
        cancellables.removeAll()
    }
    
    private func togglePlayback() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        
        // Show controls briefly
        showControlsBriefly()
    }
    
    private func seekTo(_ time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
    }
    
    private func seekBy(_ seconds: Double) {
        let newTime = max(0, min(duration, currentTime + seconds))
        seekTo(newTime)
        showControlsBriefly()
    }
    
    private func showControlsBriefly() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls = true
        }
        hideControlsAfterDelay()
    }
    
    private func hideControlsAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = false
            }
        }
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

#Preview {
    FullScreenVideoPlayerView(
        videoURL: URL(string: "https://is3.cloudhost.id/oculab-fov/DummyStitch.mp4")!
    ) {
        // Close action
    }
}
