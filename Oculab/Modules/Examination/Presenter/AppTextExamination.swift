//
//  AppTextExamination.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 02/08/25.
//

import Foundation

// MARK: Examination Module Texts
typealias AppTextExam = AppText.Examination
typealias AppTextExamProgress = AppText.Examination.ProgressView
typealias AppTextExamDetail = AppText.Examination.DetailViews
typealias AppTextExamGuidelines = AppText.Examination.GuidelinesOnboardingView
typealias AppTextExamSavedResult = AppText.Examination.SavedResultView
typealias AppTextExamCompConfirmPopups = AppText.Examination.ConfirmationPopupsComponent
typealias AppTextExamCompImageSection = AppText.Examination.ImageSectionComponent
typealias AppTextExamCompInterpretationSection = AppText.Examination.InterpretationSectionComponent
typealias AppTextExamCompLabInfo = AppText.Examination.LaborantInfoComponent
typealias AppTextExamCompHeaderView = AppText.Examination.HeaderViewComponent
typealias AppTextExamCompFolderCard = AppText.Examination.FolderCardComponent

extension AppText {
    enum Examination {
        static let titleResultImages = "examination.title_result_images".localized
        static let titleResultInterpretation = "examination.title_result_interpretation".localized
        static let buttonStartAnalysis = "examination.button_start_analysis".localized
        static let buttonSubmitting = "examination.button_submitting".localized

        enum ProgressView {
            static let loadingAnimationName = "loadingPaperplane"
            static let analyzingTitle = "examination.progress.analyzing_title".localized
            static let refreshInstruction = "examination.progress.refresh_instruction".localized
            static let backgroundInstruction = "examination.progress.background_instruction".localized
            static let buttonBackToTasks = "examination.progress.button_back_to_tasks".localized
            static let notificationReadyTitle = "examination.progress.notification_ready_title".localized
            static let notificationReadyBody = "examination.progress.notification_ready_body".localized
            static let buttonSaveResult = "examination.progress.button_save_result".localized
            static let buttonVerifyAllFOVs = "examination.progress.button_verify_fovs".localized
        }
        
        enum DetailViews {
            static let navigationTitle = "examination.detail.navigation_title".localized
            static let examinationResult1Title = AppData.resultTitle("examination.detail.specimen".localized, 1)
            static let examinationResult2Title = AppData.resultTitle("examination.detail.specimen".localized, 2)
            static let reportToSitbButton = "examination.detail.report_to_sitb".localized
            
            static let newExaminationTitle = "examination.detail.new_examination_title".localized
            static let dataPemeriksaanStep = "examination.detail.data_examination_step".localized
            static let hasilPemeriksaanStep = "examination.detail.result_examination_step".localized
            static let slideDetailTitle = "examination.detail.slide_detail_title".localized
            static let slideImageTitle = "examination.detail.slide_image_title".localized

            static let titlePatientDataCard = "examination.detail.patient_data_card".localized
            static let reviewSummaryHint = "examination.detail.review_summary_hint".localized
            static let startAnalysisHint = "examination.detail.start_analysis_hint".localized
            static let uploadingVideoMessage = AppState.loading("examination.detail.uploading_video".localized)
            static let analysisQueuedTitle = "examination.detail.analysis_queued_title".localized
            static let analysisQueuedMessage = "examination.detail.analysis_queued_message".localized
            static let analysisQueuedGoHome = "examination.detail.analysis_queued_go_home".localized
            static let analysisQueuedViewProgress = "examination.detail.analysis_queued_view_progress".localized
            static let buttonViewPDF = AppAction.view("PDF")
        }
        
        enum GuidelinesOnboardingView {
            static let navigationTitle = "examination.guidelines.navigation_title".localized
            
            struct GuidelineContent {
                let imageName: String
                let title: String
                let description: String
            }
            
            static let guidelines: [GuidelineContent] = [
                GuidelineContent(
                    imageName: "Guideline1",
                    title: "examination.guidelines.step1_title".localized,
                    description: "examination.guidelines.step1_description".localized
                ),
                GuidelineContent(
                    imageName: "Guideline2",
                    title: "examination.guidelines.step2_title".localized,
                    description: "examination.guidelines.step2_description".localized
                ),
                GuidelineContent(
                    imageName: "Guideline3",
                    title: "examination.guidelines.step3_title".localized,
                    description: "examination.guidelines.step3_description".localized
                )
            ]
        }
        
        enum SavedResultView {
            static let systemInterpretationWarning = "examination.saved.system_interpretation_warning".localized
            static let titlePatientDataCard = "examination.saved.patient_data_card".localized
            static let titleDetailsExamCard = AppData.withPrefix("examination.saved.detail_prefix".localized, "examination.saved.examination_suffix".localized)
            static let actionViewPdf = AppAction.view("PDF")
        }
        
        enum ConfirmationPopupsComponent {
            static let unfinishedExaminationTitle = "examination.popup.unfinished_title".localized
            static let unfinishedExaminationDescription = "examination.popup.unfinished_description".localized
            static let saveResultDescription = "examination.popup.save_result_description".localized
            static let reviewAgainButton = "examination.popup.review_again_button".localized
            static let saveResultButton = AppAction.save("examination.popup.examination_result".localized)
        }
        
        enum ImageSectionComponent {
            static let imageResultInstruction = "examination.image.result_instruction".localized
        }
        
        enum InterpretationSectionComponent {
            static let btaCountPlaceholder = "examination.interpretation.bta_count_placeholder".localized
            static let staffNotesPlaceholder = "examination.interpretation.staff_notes_placeholder".localized
        }
        
        enum LaborantInfoComponent {
            static let cardTitle = "examination.laborant.card_title".localized
            static let examinationOfficerTitle = "examination.laborant.officer_title".localized
            static let assignedByTitle = "examination.laborant.assigned_by_title".localized
        }
        
        enum FolderCardComponent {
            static let imageCountSuffix = "examination.folder.image_count_suffix".localized
        }
        
        enum HeaderViewComponent {
            static let newExaminationTitle = "examination.header.new_examination_title".localized
        }
    }
}
