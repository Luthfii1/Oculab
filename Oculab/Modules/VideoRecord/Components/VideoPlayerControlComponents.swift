//
//  VideoPlayerControls.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 17/08/25.
//

import SwiftUI
import AVFoundation

// MARK: - Video Player Top Controls
struct VideoPlayerTopControls: View {
    let videoURL: URL
    let currentPlaybackTime: Double
    let totalVideoDuration: Double
    let hasVideoReachedEnd: Bool
    let onClose: () -> Void
    
    var body: some View {
        HStack {
            // Close button
            Button(action: onClose) {
                Image(systemName: AppText.SystemIcon.close)
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Video information panel
            VideoInfoPanel(
                fileName: videoURL.lastPathComponent,
                currentTime: currentPlaybackTime,
                duration: totalVideoDuration,
                hasReachedEnd: hasVideoReachedEnd
            )
        }
        .padding()
    }
}

// MARK: - Video Player Bottom Controls
struct VideoPlayerBottomControls: View {
    let currentPlaybackTime: Double
    let totalVideoDuration: Double
    let isUserDragging: Bool
    let isVideoPlaying: Bool
    let hasVideoReachedEnd: Bool
    
    let onTimeChange: (Double) -> Void
    let onDragStateChange: (Bool) -> Void
    let onPlayPause: () -> Void
    let onSeekBackward: () -> Void
    let onSeekForward: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress bar section
            if totalVideoDuration > 0 {
                VideoProgressBar(
                    currentTime: currentPlaybackTime,
                    totalDuration: totalVideoDuration,
                    isDragging: isUserDragging,
                    onTimeChange: onTimeChange,
                    onDragStateChange: onDragStateChange
                )
            }
            
            // Playback buttons section
            VideoPlaybackButtons(
                isPlaying: isVideoPlaying,
                hasReachedEnd: hasVideoReachedEnd,
                onPlayPause: onPlayPause,
                onSeekBackward: onSeekBackward,
                onSeekForward: onSeekForward
            )
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
}

// MARK: - Video Progress Bar Component
struct VideoProgressBar: View {
    let currentTime: Double
    let totalDuration: Double
    let isDragging: Bool
    
    let onTimeChange: (Double) -> Void
    let onDragStateChange: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            // Time labels
            HStack {
                Text(formatTime(currentTime))
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(formatTime(totalDuration))
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            // Progress slider
            Slider(
                value: Binding(
                    get: { currentTime },
                    set: { newValue in
                        onTimeChange(newValue)
                    }
                ),
                in: 0...totalDuration,
                onEditingChanged: { editing in
                    onDragStateChange(editing)
                }
            )
            .accentColor(.white)
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        guard !time.isNaN && !time.isInfinite && time >= 0 else {
            return "0:00"
        }
        
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return String(format: "%d:%02d:%02d", hours, remainingMinutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Video Playback Buttons Component
struct VideoPlaybackButtons: View {
    let isPlaying: Bool
    let hasReachedEnd: Bool
    
    let onPlayPause: () -> Void
    let onSeekBackward: () -> Void
    let onSeekForward: () -> Void
    
    var body: some View {
        HStack(spacing: 30) {
            // Rewind 15 seconds button
            Button(action: onSeekBackward) {
                Image(systemName: "gobackward.15")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            // Main play/pause/replay button
            Button(action: onPlayPause) {
                Image(systemName: getPlayButtonIconName())
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            // Forward 15 seconds button
            Button(action: onSeekForward) {
                Image(systemName: "goforward.15")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
    }
    
    private func getPlayButtonIconName() -> String {
        if hasReachedEnd {
            return "arrow.counterclockwise.circle.fill"  // Replay icon
        } else if isPlaying {
            return "pause.circle.fill"  // Pause icon
        } else {
            return "play.circle.fill"   // Play icon
        }
    }
}

// MARK: - Video Information Panel
struct VideoInfoPanel: View {
    let fileName: String
    let currentTime: Double
    let duration: Double
    let hasReachedEnd: Bool
    
    var body: some View {
        VStack(alignment: .trailing) {
            Text(fileName)
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
    
    private func formatTime(_ time: Double) -> String {
        guard !time.isNaN && !time.isInfinite && time >= 0 else {
            return "0:00"
        }
        
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return String(format: "%d:%02d:%02d", hours, remainingMinutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Preview Provider
struct VideoPlayerControls_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VideoPlayerTopControls(
                videoURL: URL(string: "file://sample_video.mp4")!,
                currentPlaybackTime: 45.5,
                totalVideoDuration: 120.0,
                hasVideoReachedEnd: false
            ) {
                print("Close tapped")
            }
            .previewDisplayName("Top Controls")
            .background(Color.black)
            
            VideoPlayerBottomControls(
                currentPlaybackTime: 45.5,
                totalVideoDuration: 120.0,
                isUserDragging: false,
                isVideoPlaying: true,
                hasVideoReachedEnd: false,
                onTimeChange: { _ in },
                onDragStateChange: { _ in },
                onPlayPause: { },
                onSeekBackward: { },
                onSeekForward: { }
            )
            .previewDisplayName("Bottom Controls")
            .background(Color.black)
            
            VideoPlaybackButtons(
                isPlaying: false,
                hasReachedEnd: true,
                onPlayPause: { },
                onSeekBackward: { },
                onSeekForward: { }
            )
            .previewDisplayName("Playback Buttons")
            .background(Color.black)
        }
    }
}
