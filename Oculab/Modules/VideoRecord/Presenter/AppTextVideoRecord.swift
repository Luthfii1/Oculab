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
            static let cameraAccessDeniedTitle = "video_record.video_record_view.camera_access_denied_title".localized
            static let cameraAccessDeniedMessage = "video_record.video_record_view.camera_access_denied_message".localized
            static let goToSettingsButton = "video_record.video_record_view.go_to_settings_button".localized
            
            static func videoFileDateAndExtension() -> String {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                return "\(formatter.string(from: Date())).mov"
            }

            static func specimenTitle(_ specimenId: String) -> String {
                let format = NSLocalizedString("video_record.video_record_view.specimen_title", comment: AppValue.empty)
                return String(format: format, specimenId)
            }
            
            static let specimenTitleDefault = "video_record.video_record_view.specimen_title_default".localized
        }
        
        enum InstructionRecordView {
            static let navigationTitle = "video_record.instruction_record_view.navigation_title".localized
            static let preparationSectionTitle = "video_record.instruction_record_view.preparation_section_title".localized
            static let recordingSectionTitle = "video_record.instruction_record_view.recording_section_title".localized
            static let startRecordingButton = "video_record.instruction_record_view.start_recording_button".localized

            // MARK: - Instruction Arrays
            static let preRecordingInstructions: [String] = [
                "video_record.instruction_record_view.pre_recording_instruction_1".localized,
                "video_record.instruction_record_view.pre_recording_instruction_2".localized,
                "video_record.instruction_record_view.pre_recording_instruction_3".localized,
                "video_record.instruction_record_view.pre_recording_instruction_4".localized
            ]
            
            static let duringRecordingInstructions: [String] = [
                "video_record.instruction_record_view.during_recording_instruction_1".localized,
                "video_record.instruction_record_view.during_recording_instruction_2".localized,
                "video_record.instruction_record_view.during_recording_instruction_3".localized
            ]
        }
        
        enum StitchedImageView {
            static let navigationTitle = "video_record.stitched_image_view.navigation_title".localized
            static let noImageAvailableMessage = "video_record.stitched_image_view.no_image_available_message".localized
        }
        
        enum FullScreenVideoPlayerView {
            // Empty enum for consistency, no specific strings needed
        }
        
        enum CameraViewComponent {
            static let cameraAccessAlertTitle = "video_record.camera_view_component.camera_access_alert_title".localized
            static let cameraAccessAlertMessage = "video_record.camera_view_component.camera_access_alert_message".localized
            static let settingsButton = "video_record.camera_view_component.settings_button".localized
        }
        
        enum VideoPreviewComponent {
            static let saveVideoButton = "video_record.video_preview_component.save_video_button".localized
            static let retakeVideoButton = "video_record.video_preview_component.retake_video_button".localized
        }
        
        enum VideoInputComponent {
            static let videoErrorAlertMessage = "video_record.video_input_component.video_error_alert_message".localized
            static let createVideoButton = "video_record.video_input_component.create_video_button".localized
            static let viewVideoButton = "video_record.video_input_component.view_video_button".localized
            static let videoPlaybackErrorTitle = "video_record.video_input_component.video_playback_error_title".localized
        }
    }
}
