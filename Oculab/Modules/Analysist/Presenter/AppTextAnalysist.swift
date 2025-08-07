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
            static let stepTitles = ["Data Pemeriksaan", "Hasil Pemeriksaan"]
            static let currentStepIndex = 1
            static let loadingExaminationMessage = AppState.loading("data pemeriksaan")
        }
        
        enum InformationPageView {
            static let navigationTitle = "Informasi Interpretasi Sistem"
            static let assessmentStandardTitle = "Standar Penilaian"
            static let assessmentStandardDescription = "Sistem ini menghitung bakteri sesuai rekomendasi WHO dan standar IUALTD"
            
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
            static let loadingDataMessage = AppState.loading("data pemeriksaan")
        }
        
        enum PDFView {
            static let loadingAnimationName = "loadingPaperplane"
            static let downloadingDataMessage = AppState.loading("data")
            static let takenAtLabel = "Diambil di"
            static let officerLabel = "Petugas"
            static let noNotesDefault = AppState.noData("catatan") 
            static let reportingHeaderTitle = "Pelaporan"
            static let observationResultsHeaderTitle = "Hasil Pengamatan"
            
            // Table Content
            static let bacteriologicalExaminationResultTitle = "HASIL PEMERIKSAAN BAKTERIOLOGIS"
            
            // Signature Section
            static let labOfficerSignatureTitle = "Petugas Lab"
            static let supervisingDoctorSignatureTitle = "Dokter PJ Pemeriksaan Lab"
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
