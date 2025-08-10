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
        static let titleResultImages = "Hasil Gambar"
        static let titleResultInterpretation = "Hasil Interpretasi"
        static let buttonStartAnalysis = "Mulai Analisis"
        static let buttonSubmitting = "Mengirimkan..."

        enum ProgressView {
            static let loadingAnimationName = "loadingPaperplane"
            static let analyzingTitle = "Menginterpretasikan data"
            static let refreshInstruction = "Tarik ke bawah untuk memuat ulang"
            static let buttonSaveResult = "Simpan Hasil Pemeriksaan"
            static let buttonVerifyAllFOVs = "Verikasi Semua Lapang Pandang"
        }
        
        enum DetailViews {
            static let navigationTitle = "Detail Pemeriksaan"
            static let examinationResult1Title = AppData.resultTitle("Sediaan", 1)
            static let examinationResult2Title = AppData.resultTitle("Sediaan", 2)
            static let reportToSitbButton = "Laporkan ke SITB"
            
            static let newExaminationTitle = "Pemeriksaan Baru"
            static let dataPemeriksaanStep = "Data Pemeriksaan"
            static let hasilPemeriksaanStep = "Hasil Pemeriksaan"
            static let slideDetailTitle = "Detail Sediaan"
            static let slideImageTitle = "Gambar Sediaan"

            static let titlePatientDataCard = "Data Pasien"
            static let buttonViewPDF = AppAction.view("PDF")
        }
        
        enum GuidelinesOnboardingView {
            static let navigationTitle = "Persiapan Pemeriksaan"
            
            struct GuidelineContent {
                let imageName: String
                let title: String
                let description: String
            }
            
            static let guidelines: [GuidelineContent] = [
                GuidelineContent(
                    imageName: "Guideline1",
                    title: "Temukan Lapang Pandang pada Mikroskop",
                    description: "Teteskan minyak imersi pada kaca sediaan dan atur lensa objektif ke perbesaran 100x"
                ),
                GuidelineContent(
                    imageName: "Guideline2",
                    title: "Pasang Smartphone pada Adapter",
                    description: "Bersihkan lensa kamera utama dan sejajarkan dengan lubang adapter"
                ),
                GuidelineContent(
                    imageName: "Guideline3",
                    title: "Pasang Adapter pada Mikroskop",
                    description: "Pasang adapter ke lensa okuler dan atur fokus antara mikroskop dan kamera"
                )
            ]
        }
        
        enum SavedResultView {
            static let systemInterpretationWarning = "Interpretasi sistem bukan merupakan hasil akhir untuk pasien"
            static let titlePatientDataCard = "Data Pasien"
            static let titleDetailsExamCard = AppData.withPrefix("Detail", "Pemeriksaan")
            static let actionViewPdf = AppAction.view("PDF")
        }
        
        enum ConfirmationPopupsComponent {
            static let unfinishedExaminationTitle = "Pemeriksaan Belum Selesai"
            static let unfinishedExaminationDescription = "Pemeriksaan disimpan sebagai draft dan dapat diakses di halaman riwayat"
            static let saveResultDescription = "Hasil pemeriksaan yang sudah disimpan tidak dapat diubah kembali"
            static let reviewAgainButton = "Periksa Kembali"
            static let saveResultButton = AppAction.save("Hasil Pemeriksaan")
        }
        
        enum ImageSectionComponent {
            static let imageResultInstruction = "Ketuk untuk lihat detail gambar"
        }
        
        enum InterpretationSectionComponent {
            static let btaCountPlaceholder = "Contoh: 8"
            static let staffNotesPlaceholder = "Contoh: Hanya terdapat 20 bakteri dari 60 lapangan pandang yang terkumpul"
        }
        
        enum LaborantInfoComponent {
            static let examinationOfficerTitle = "Petugas Pemeriksaan"
            static let assignedByTitle = "Ditugaskan Oleh"
        }
        
        enum FolderCardComponent {
            static let imageCountSuffix = "Gambar"
        }
        
        enum HeaderViewComponent {
            static let newExaminationTitle = "Pemeriksaan Baru"
        }
    }
}
