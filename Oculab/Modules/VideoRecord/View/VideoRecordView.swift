//
//  VideoRecordView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 14/10/24.
//

import AVKit
import SwiftUI

struct VideoRecordView: View {
    @ObservedObject private var videoRecordPresenter = VideoRecordSession.current
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var isCameraScreenVisible = false
    @State private var showGuidelines = false
    @State private var didFinishOnboarding = false
    let slideId: String

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
                if shouldShowCameraPreparation {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView(AppTextVideoRecordView.settingUpCamera)
                        .tint(.white)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)
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
        .task(id: videoRecordPresenter.previewURL == nil) {
            videoRecordPresenter.setSpecimenTitle(specimenId: slideId)
            // Retake clears the preview while this screen stays mounted.
            guard videoRecordPresenter.previewURL == nil else { return }
            await videoRecordPresenter.checkPermission()
        }
        .onAppear { isCameraScreenVisible = true }
        .onChange(of: scenePhase) { _, phase in
            // Granting access in Settings does not remount this screen.
            guard phase == .active, isCameraScreenVisible,
                  videoRecordPresenter.previewURL == nil else { return }
            Task {
                guard isCameraScreenVisible else { return }
                await videoRecordPresenter.checkPermission()
            }
        }
        .onDisappear {
            isCameraScreenVisible = false
            // Enqueue teardown now; a delayed outer Task could stop an immediately reopened camera.
            videoRecordPresenter.endSession()
        }
        .alert(isPresented: $videoRecordPresenter.alert) {
            cameraAccessAlert
        }
        .alert("Error", isPresented: .constant(videoRecordPresenter.errorMessage != nil)) {
            Button(AppAction.retry) {
                Task {
                    guard isCameraScreenVisible else { return }
                    await videoRecordPresenter.retryCameraStartup()
                }
            }
            Button(AppAction.cancel, role: .cancel) {
                videoRecordPresenter.errorMessage = nil
                videoRecordPresenter.navigateBack()
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
    
    private var shouldShowCameraPreparation: Bool {
        videoRecordPresenter.previewURL == nil
            && !videoRecordPresenter.isRecording
            && (!videoRecordPresenter.isCameraReady || videoRecordPresenter.isLoading)
            && !videoRecordPresenter.alert
            && videoRecordPresenter.errorMessage == nil
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
//
//#Preview {
//    VideoRecordView()
//}
