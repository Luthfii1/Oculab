//
//  AppTextVideoRecord.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 02/08/25.
//

import Foundation

// MARK: VideoRecord Module Texts
typealias AppTextVideoRecordView = AppText.VideoRecord.VideoRecordView
typealias AppTextVideoRecordInstruction = AppText.VideoRecord.InstructionRecordView
typealias AppTextVideoRecordStitched = AppText.VideoRecord.StitchedImageView
typealias AppTextVideoRecordFullScreen = AppText.VideoRecord.FullScreenVideoPlayerView
typealias AppTextVideoRecordCompCamera = AppText.VideoRecord.CameraViewComponent
typealias AppTextVideoRecordCompPreview = AppText.VideoRecord.VideoPreviewComponent
typealias AppTextVideoRecordCompInput = AppText.VideoRecord.VideoInputComponent

extension AppText {
    enum VideoRecord {
        enum VideoRecordView {
            static let cameraAccessDeniedTitle = "Akses Kamera Ditolak"
            static let cameraAccessDeniedMessage = "Silakan aktifkan akses kamera untuk Oculab di Pengaturan untuk merekam video"
            static let goToSettingsButton = "Buka Pengaturan"
        }
        
        enum InstructionRecordView {
            static let navigationTitle = "Instruksi Pemeriksaan"
            static let preparationSectionTitle = "Persiapan Pemeriksaan"
            static let recordingSectionTitle = "Instruksi Pengambilan Gambar"
            static let startRecordingButton = "Mulai Pengambilan Gambar"
        }
        
        enum StitchedImageView {
            static let navigationTitle = "Gambar Stitched"
            static let noImageAvailableMessage = "Tidak ada gambar yang tersedia"
        }
        
        enum FullScreenVideoPlayerView {
            // Empty enum for consistency, no specific strings needed
        }
        
        enum CameraViewComponent {
            static let cameraAccessAlertTitle = "Akses Kamera"
            static let cameraAccessAlertMessage = "Silakan aktifkan akses kamera dan mikrofon di pengaturan"
            static let settingsButton = "Buka Pengaturan"
            static let cancelButton = AppAction.cancel
        }
        
        enum VideoPreviewComponent {
            static let saveVideoButton = "Simpan Video"
            static let retakeVideoButton = "Ambil Ulang"
        }
        
        enum VideoInputComponent {
            static let videoErrorAlertMessage = "Video tidak dapat diputar. Silakan rekam ulang sampel."
        }
    }
}