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
            
            static func videoFileDateAndExtension() -> String {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                return "\(formatter.string(from: Date())).mov"
            }

            static func specimenTitle(_ specimenId: String) -> String {
                return "Sediaan: \(specimenId)"
            }
            
            static let specimenTitleDefault = "Sediaan: -"
        }
        
        enum InstructionRecordView {
            static let navigationTitle = "Instruksi Pemeriksaan"
            static let preparationSectionTitle = "Persiapan Pemeriksaan"
            static let recordingSectionTitle = "Instruksi Pengambilan Gambar"
            static let startRecordingButton = "Mulai Pengambilan Gambar"

            // MARK: - Instruction Arrays
            static let preRecordingInstructions: [String] = [
                "Gunakan lensa objektif 10x untuk menentukan fokus, kemudian teteskan minyak imersi",
                "Pastikan lensa objektif telah diatur ke perbesaran 100x setelah fokus ditemukan",
                "Pasang perangkat Anda dengan lensa kamera menempel pada lensa okuler",
                "Pastikan Anda berada di lokasi dengan jaringan yang lancar"
            ]
            
            static let duringRecordingInstructions: [String] = [
                "Pastikan sediaan tetap terlihat di layar dan selalu dalam fokus optimal",
                "Baca sediaan mulai dari ujung kiri ke ujung kanan mengikuti skema pemindaian untuk pemeriksaan apusan",
                "Progress pengambilan gambar keseluruhan akan terlihat di kanan atas"
            ]
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
        }
        
        enum VideoPreviewComponent {
            static let saveVideoButton = "Simpan Video"
            static let retakeVideoButton = "Ambil Ulang"
        }
        
        enum VideoInputComponent {
            static let videoErrorAlertMessage = "Video tidak dapat diputar. Silakan rekam ulang sampel."
            static let createVideoButton = "Gambar"
            static let viewVideoButton = "Video"
            static let videoPlaybackErrorTitle = "Memutar Video"
        }
    }
}
