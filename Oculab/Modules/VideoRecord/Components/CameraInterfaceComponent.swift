//
//  CameraView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 14/10/24.
//

import AVFoundation
import SwiftUI

struct CameraView: View {
    @EnvironmentObject private var videoRecordPresenter: VideoRecordPresenter
    @State private var showZoomGesture = false

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                // Camera preview
                CameraPreviewComponent(size: size)
                    .environmentObject(videoRecordPresenter)
                
                // Overlay controls
                VStack {
                    // Top controls
                    topControlsOverlay
                    
                    Spacer()
                    
                    // Bottom controls
                    bottomControlsOverlay
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
                
                // Zoom indicator
                if showZoomGesture {
                    zoomIndicator
                }
            }
        }
        .onAppear {
            Task {
                // Ensure camera session is running when view appears
                if !videoRecordPresenter.session.isRunning {
                    await videoRecordPresenter.checkPermission()
                }
            }
        }
        .alert(isPresented: $videoRecordPresenter.alert) {
            cameraAccessAlert
        }
        .onChange(of: videoRecordPresenter.zoomFactor) { _, newValue in
            showZoomIndicator()
        }
    }
    
    // MARK: - Subviews
    private var topControlsOverlay: some View {
        HStack {
            Spacer()
            
            // Zoom level indicator
            if videoRecordPresenter.zoomFactor > 1.0 {
                Text("\(String(format: "%.1fx", videoRecordPresenter.zoomFactor))")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
            }
        }
    }
    
    private var bottomControlsOverlay: some View {
        HStack {
            Spacer()
            
            // Record button
            recordButton
            
            Spacer()
        }
    }
    
    private var recordButton: some View {
        Button(action: {
            Task { @MainActor in
                videoRecordPresenter.handleButtonRecording()
            }
        }) {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .fill(videoRecordPresenter.getColorButtonRecording())
                    .frame(width: videoRecordPresenter.isRecording ? 32 : 60,
                           height: videoRecordPresenter.isRecording ? 32 : 60)
                    .animation(.easeInOut(duration: 0.2), value: videoRecordPresenter.isRecording)
                
                if videoRecordPresenter.isRecording {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                }
            }
        }
        .scaleEffect(videoRecordPresenter.isRecording ? 0.9 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: videoRecordPresenter.isRecording)
    }
    
    private var zoomIndicator: some View {
        VStack {
            Text("\(String(format: "%.1fx", videoRecordPresenter.zoomFactor))")
                .font(.system(.title2, design: .monospaced, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.7))
                .cornerRadius(20)
                .shadow(radius: 4)
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    private var cameraAccessAlert: Alert {
        Alert(
            title: Text(AppTextVideoRecordCompCamera.cameraAccessAlertTitle),
            message: Text(AppTextVideoRecordCompCamera.cameraAccessAlertMessage),
            primaryButton: .default(Text(AppTextVideoRecordCompCamera.settingsButton)) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            },
            secondaryButton: .cancel(Text(AppAction.cancel))
        )
    }
    
    // MARK: - Methods
    private func showZoomIndicator() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showZoomGesture = true
        }
        
        // Hide after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showZoomGesture = false
            }
        }
    }
}

#Preview {
    CameraView()
        .environmentObject(VideoRecordSession.current)
}
