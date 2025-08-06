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

            static let bulletPoint = AppValue.bullet
            static let confidenceLevelTitle = AppMedical.Examination.confidenceLevel
            static let negativeDescription = AppMedical.BTA.Description.negative
            static let scantyDescription = AppMedical.BTA.Description.scanty
            static let positive1Description = AppMedical.BTA.Description.positive1
            static let positive2Description = AppMedical.BTA.Description.positive2
            static let positive3Description = AppMedical.BTA.Description.positive3
            static let perfectConfidenceDescription = AppMedical.Confidence.perfect
            static let highConfidenceDescription = AppMedical.Confidence.high
            static let mediumConfidenceDescription = AppMedical.Confidence.medium
            static let lowConfidenceDescription = AppMedical.Confidence.low
            static let veryLowConfidenceDescription = AppMedical.Confidence.veryLow
            static let unpredictedConfidenceDescription = AppMedical.Confidence.unpredicted
        }
        
        enum FOVDetailView {
            static let loadingDataMessage = AppState.loading("data pemeriksaan")
            static func bacteriaCountPrefix(_ count: String) -> String {
                return AppData.withPrefix("Jumlah Bakteri:", count)
            }
            static func slideIdPrefix(_ id: String) -> String {
                return AppData.withPrefix("ID", id)
            }
        }
        
        enum PDFView {
            static let loadingAnimationName = "loadingPaperplane"
            static let downloadingDataMessage = AppState.loading("data")
            
            static let examinationIdLabel = AppMedical.Examination.examinationId 
            static let takenAtLabel = "Diambil di"
            static let officerLabel = "Petugas"
            static let noNotesDefault = AppState.noData("catatan") 
            static let reportingHeaderTitle = "Pelaporan"
            static let observationResultsHeaderTitle = "Hasil Pengamatan"
            
            // Table Content
            static let bacteriologicalExaminationResultTitle = "HASIL PEMERIKSAAN BAKTERIOLOGIS"
            static let testTypeLabel = AppLabel.type 
            
            // Signature Section
            static let labOfficerSignatureTitle = "Petugas Lab"
            static let supervisingDoctorSignatureTitle = "Dokter PJ Pemeriksaan Lab"
            
            static let nikLabel = AppPatient.nik
            static let ageLabel = AppPatient.age
            static let genderLabel = AppPatient.gender
            static let bpjsLabel = AppPatient.bpjsNumber
            static let ageSuffix = AppPatient.ageSuffix
            static let specimenInfoTitle = AppMedical.Examination.specimenInfo
            static let microscopicInterpretationTitle = AppMedical.Examination.microscopicInterpretation
            static let staffNotesTitle = AppLabel.notes
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