//
//  VideoRecordView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 14/10/24.
//

import AVKit
import SwiftUI

struct VideoRecordView: View {
    @StateObject private var videoRecordPresenter = VideoRecordPresenter.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showGuidelines = false
    @State private var didFinishOnboarding = false 

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Main Content
                if videoRecordPresenter.previewURL != nil {
                    // Video Preview Mode
                    VideoPreview()
                        .environmentObject(videoRecordPresenter)
                } else {
                    // Camera Recording Mode
                    CameraView()
                        .environmentObject(videoRecordPresenter)
                        .ignoresSafeArea()

                    // Overlay elements
                    VStack {
                        // Recording duration display
                        if videoRecordPresenter.isRecording {
                            recordingDurationOverlay
                        }
                        
                        Spacer()
                        
                        // Picture-in-picture view during recording
                        if videoRecordPresenter.isRecording && videoRecordPresenter.showPlayerView {
                            pictureInPictureView
                        }
                    }
                }
                
                // Loading overlay
                if videoRecordPresenter.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView("Setting up camera...")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Back button
                if videoRecordPresenter.isBackButtonActive() {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            videoRecordPresenter.navigateBack()
                        }) {
                            Image(systemName: AppText.SystemIcon.backCircle)
                                .foregroundStyle(AppColors.slate0)
                        }
                    }
                }

                // Title
                ToolbarItem(placement: .principal) {
                    if videoRecordPresenter.showRecordingTitle {
                        Text(videoRecordPresenter.videoRecordingTitle)
                            .foregroundStyle(AppColors.slate0)
                            .shadow(color: Color.black.opacity(0.4), radius: 2, x: 1, y: 1)
                            .font(AppTypography.s4)
                    }
                }

                // Info button
                if videoRecordPresenter.isInformationButtonActive() {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showGuidelines = true
                        }) {
                            Image(systemName: AppText.SystemIcon.info)
                                .foregroundStyle(AppColors.slate0)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            Task {
                // If we have a preview URL, we're returning from preview mode
                // Need to reinitialize camera for new recording
                if videoRecordPresenter.previewURL != nil {
                    await videoRecordPresenter.resetForNewSession()
                } else {
                    await videoRecordPresenter.checkPermission()
                }
            }
        }
        .onDisappear {
            Task {
                await videoRecordPresenter.cleanup()
            }
        }
        .alert(isPresented: $videoRecordPresenter.alert) {
            cameraAccessAlert
        }
        .alert("Error", isPresented: .constant(videoRecordPresenter.errorMessage != nil)) {
            Button("OK") {
                videoRecordPresenter.errorMessage = nil
            }
        } message: {
            if let errorMessage = videoRecordPresenter.errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $showGuidelines, onDismiss: {
            didFinishOnboarding = true
        }) {
            GuidelinesOnboardingView()
        }
    }
    
    // MARK: - Subviews
    private var recordingDurationOverlay: some View {
        HStack {
            Image(systemName: "record.circle.fill")
                .foregroundColor(.red)
                .font(.caption)
            
            Text(videoRecordPresenter.getFormattedRecordingDuration())
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.6))
        .cornerRadius(16)
        .padding(.top, 8)
    }
    
    private var pictureInPictureView: some View {
        VStack {
            HStack {
                Spacer()
                
                VideoPlayerView()
                    .frame(width: 187, height: 111)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .padding(.trailing, 20)
                    .padding(.top, 60)
            }
            
            Spacer()
        }
    }
    
    private var cameraAccessAlert: Alert {
        Alert(
            title: Text(AppTextVideoRecordView.cameraAccessDeniedTitle),
            message: Text(AppTextVideoRecordView.cameraAccessDeniedMessage),
            primaryButton: .default(Text(AppTextVideoRecordView.goToSettingsButton)) {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            },
            secondaryButton: .cancel(Text(AppAction.cancel)) {
                dismiss()
            }
        )
    }
}

#Preview {
    VideoRecordView()
}
