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
            static let loadingDataMessage = AppState.loading("analysist.examination_data".localized)
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
    }
}
