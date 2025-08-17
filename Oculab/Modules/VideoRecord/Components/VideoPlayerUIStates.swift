//
//  VideoPlayerUIStates.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 17/08/25.
//

import SwiftUI

// MARK: - Video Player Loading State Component
struct VideoPlayerLoadingState: View {
    var body: some View {
        VStack(spacing: 20) {
            // Loading spinner
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            // Loading message
            VStack(spacing: 8) {
                Text("Loading Video")
                    .foregroundColor(.white)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Please wait while we prepare your video...")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
    }
}

// MARK: - Video Player Error State Component
struct VideoPlayerErrorState: View {
    let errorMessage: String?
    let onRetry: () -> Void
    let onClose: () -> Void
    
    // Default initializer for backward compatibility
    init(onClose: @escaping () -> Void) {
        self.errorMessage = nil
        self.onRetry = {}
        self.onClose = onClose
    }
    
    // Enhanced initializer with retry functionality
    init(errorMessage: String? = nil, onRetry: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.errorMessage = errorMessage
        self.onRetry = onRetry
        self.onClose = onClose
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            // Error messages
            VStack(spacing: 12) {
                Text("Video Playback Error")
                    .foregroundColor(.white)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(errorMessage ?? "Failed to load video. Please check your connection and try again.")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Action buttons
            VStack(spacing: 12) {
                // Retry button
                Button(action: onRetry) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                // Close button
                Button(action: onClose) {
                    Text("Close")
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.9))
    }
}

// MARK: - Video Player Empty State Component
struct VideoPlayerEmptyState: View {
    let message: String
    let onAction: (() -> Void)?
    let actionTitle: String?
    
    init(message: String = "No video selected", actionTitle: String? = nil, onAction: (() -> Void)? = nil) {
        self.message = message
        self.actionTitle = actionTitle
        self.onAction = onAction
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Empty state icon
            Image(systemName: "play.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            // Empty state message
            VStack(spacing: 8) {
                Text("No Video")
                    .foregroundColor(.white)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(message)
                    .foregroundColor(.white.opacity(0.7))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
            
            // Optional action button
            if let actionTitle = actionTitle, let onAction = onAction {
                Button(action: onAction) {
                    Text(actionTitle)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
    }
}

// MARK: - Preview Provider
struct VideoPlayerUIStates_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VideoPlayerLoadingState()
                .previewDisplayName("Loading State")
            
            VideoPlayerErrorState(
                errorMessage: "Network connection failed. Please check your internet and try again.",
                onRetry: { print("Retry tapped") },
                onClose: { print("Close tapped") }
            )
            .previewDisplayName("Error State")
            
            VideoPlayerEmptyState(
                message: "Select a video file to start playing",
                actionTitle: "Browse Files",
                onAction: { print("Browse tapped") }
            )
            .previewDisplayName("Empty State")
        }
    }
}

// MARK: - Backward Compatibility Aliases
// These maintain compatibility with existing code
typealias VideoPlayerLoadingView = VideoPlayerLoadingState
typealias VideoPlayerErrorView = VideoPlayerErrorState
