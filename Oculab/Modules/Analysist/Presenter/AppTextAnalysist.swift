//
//  AppTextAnalysist.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 02/08/25.
//

import Foundation

// MARK: Analysist Module Texts
typealias AppTextAnalysisResult = AppText.Analysist.AnalysisResultView
typealias AppTextAnalysisInformation = AppText.Analysist.InformationPageView
typealias AppTextAnalysisFOVDetail = AppText.Analysist.FOVDetailView
typealias AppTextAnalysisPDF = AppText.Analysist.PDFView
typealias AppTextAnalysisFOVAlbum = AppText.Analysist.FOVAlbumView
typealias AppTextAnalysisCompZoomable = AppText.Analysist.ZoomableImageComponent
typealias AppTextAnalysisVerifSheet = AppText.Analysist.VerificationSheet

extension AppText {
    enum Analysist {
        enum AnalysisResultView {
            static let stepTitles = ["analysist.step.data_examination".localized, "analysist.step.examination_results".localized]
            static let currentStepIndex = 1
            static let loadingExaminationMessage = AppState.loading("analysist.examination_data".localized)
        }
        
        enum InformationPageView {
            static let navigationTitle = "analysist.info.navigation_title".localized
            static let assessmentStandardTitle = "analysist.info.assessment_standard_title".localized
            static let assessmentStandardDescription = "analysist.info.assessment_standard_description".localized
            
            // MARK: - Grouped Data for Clean UI Implementation
            static let btaDescriptions: [String] = [
                AppMedical.BTA.Description.negative,
                AppMedical.BTA.Description.scanty,
                AppMedical.BTA.Description.positive1,
                AppMedical.BTA.Description.positive2,
                AppMedical.BTA.Description.positive3
            ]
            
            static let confidenceDescriptions: [String] = [
                AppMedical.Confidence.perfect,
                AppMedical.Confidence.high,
                AppMedical.Confidence.medium,
                AppMedical.Confidence.low,
                AppMedical.Confidence.veryLow,
                AppMedical.Confidence.unpredicted
            ]
        }
        
        enum FOVDetailView {
            static let navigationTitle = "analysist.fov_detail.navigation_title".localized
            static let loadingDataMessage = AppState.loading("analysist.examination_data".localized)
            static let processingInProgressTitle = "analysist.fov_detail.processing_in_progress".localized
            static let boundingBoxNotAvailableMessage = "analysist.fov_detail.bounding_box_not_available".localized
            static let errorLoadingDataTitle = "analysist.fov_detail.error_loading_data".localized
            static let retryButtonTitle = "common.retry".localized
            static let allBacteriaReviewedMessage = "analysist.fov_detail.all_reviewed".localized
            static let reviewRemainingButton = "analysist.fov_detail.review_remaining".localized
            static let startFromFirstButton = "analysist.fov_detail.start_from_first".localized
            static let tapToReviewHint = "analysist.fov_detail.tap_to_review_hint".localized
            static let swipeBetweenImagesHint = "analysist.fov_detail.swipe_hint".localized

            static func remainingToVerifyFormat(_ remaining: Int, _ total: Int) -> String {
                "analysist.fov_detail.remaining_to_verify".localized(with: remaining, total)
            }

            static func pendingReviewFormat(_ count: Int) -> String {
                "analysist.fov_detail.pending_review".localized(with: count)
            }
        }
        
        enum PDFView {
            static let loadingAnimationName = "loadingPaperplane"
            static let downloadingDataMessage = AppState.loading("analysist.data".localized)
            static let takenAtLabel = "analysist.pdf.taken_at".localized
            static let officerLabel = "analysist.pdf.officer".localized
            static let noNotesDefault = AppState.noData("analysist.notes".localized) 
            static let reportingHeaderTitle = "analysist.pdf.reporting_header".localized
            static let observationResultsHeaderTitle = "analysist.pdf.observation_results_header".localized
            
            // Table Content
            static let bacteriologicalExaminationResultTitle = "analysist.pdf.bacteriological_examination_title".localized
            
            // Signature Section
            static let labOfficerSignatureTitle = "analysist.pdf.lab_officer_signature".localized
            static let supervisingDoctorSignatureTitle = "analysist.pdf.supervising_doctor_signature".localized
            static let generatedPDFFileName = "GeneratedPDF.pdf"
        }
        
        enum FOVAlbumView {
            static func navigationTitleFormat(_ itemName: String) -> String {
                return AppData.albumTitle(itemName)
            }
        }
        
        enum ZoomableImageComponent {
            // This component is mostly UI interaction based, no specific text constants needed
        }
        
        enum VerificationSheet {
            static let title = "analysist.verification.sheet.title".localized
            static let verifyingButton = "analysist.verification.sheet.verif_button".localized
            static let flaggingButton = "analysist.verification.sheet.flag_button".localized
            static let deletingButton = "analysist.verification.sheet.delete_button".localized
            
            static func indexBacilliFormat(_ index: String) -> String {
                return "analysist.verification.sheet.index_bacilli".localized(with: index)
            }

            static func progressBacilliFormat(_ index: String, _ total: String) -> String {
                "analysist.verification.sheet.progress_bacilli".localized(with: index, total)
            }
        }
    }
}
