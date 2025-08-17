//
//  VideoPlayerManager.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 17/08/25.
//

import SwiftUI
import AVFoundation
import Combine

// MARK: - Video Player Manager
@MainActor
class VideoPlayerManager: ObservableObject {
    // MARK: - Published Properties
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isDragging = false
    @Published var hasError = false
    @Published var isLoading = true
    @Published var hasReachedEnd = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let videoURL: URL
    
    // MARK: - Initialization
    init(videoURL: URL) {
        self.videoURL = videoURL
    }
    
    // MARK: - Public Methods
    func setupPlayer() {
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
        
        // Load duration and setup monitoring
        loadVideoAsset()
        setupPlayerMonitoring(playerItem: playerItem)
        
        // Auto-play after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if !self.hasError && !self.isLoading {
                Logger.info("Starting video playback", category: .videoRecord)
                player.play()
            }
        }
    }
    
    func togglePlayback() {
        guard let player = player else { return }
        
        if hasReachedEnd {
            replayVideo()
        } else if isPlaying {
            player.pause()
        } else {
            player.play()
        }
    }
    
    func seekTo(_ time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
        
        // Reset end state if seeking away from end
        if hasReachedEnd && time < duration - 0.1 {
            hasReachedEnd = false
        }
    }
    
    func seekBy(_ seconds: Double) {
        let newTime = max(0, min(duration, currentTime + seconds))
        seekTo(newTime)
    }
    
    func cleanup() {
        player?.pause()
        player = nil
        cancellables.removeAll()
    }
    
    // MARK: - Private Methods
    private func loadVideoAsset() {
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
    }
    
    private func setupPlayerMonitoring(playerItem: AVPlayerItem) {
        guard let player = player else { return }
        
        // Monitor playback state
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.isPlaying = (status == .playing)
                Logger.info("Player status changed to: \(status)", category: .videoRecord)
            }
            .store(in: &cancellables)
        
        // Monitor player item status
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .readyToPlay:
                    self?.isLoading = false
                    Logger.info("Video player ready to play", category: .videoRecord)
                case .failed:
                    self?.hasError = true
                    self?.isLoading = false
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
        ) { [weak self] time in
            guard let self = self, !self.isDragging else { return }
            let newTime = CMTimeGetSeconds(time)
            self.currentTime = newTime
            
            // Check if video has reached the end
            if self.duration > 0 && abs(newTime - self.duration) < 0.1 {
                self.hasReachedEnd = true
                self.isPlaying = false
                Logger.info("Video reached end", category: .videoRecord)
            }
        }
        
        // Monitor for video end notification
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.hasReachedEnd = true
                self?.isPlaying = false
                Logger.info("Video finished playing", category: .videoRecord)
            }
            .store(in: &cancellables)
    }
    
    private func replayVideo() {
        guard let player = player else { return }
        
        let startTime = CMTime.zero
        player.seek(to: startTime) { [weak self] _ in
            DispatchQueue.main.async {
                self?.hasReachedEnd = false
                self?.currentTime = 0
                player.play()
                Logger.info("Video replaying from start", category: .videoRecord)
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
}
