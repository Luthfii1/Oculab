//
//  AppTextTaskAssignment.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 02/08/25.
//

import Foundation

// MARK: TaskAssignment Module Texts
typealias AppTextTaskAssignInputPatient = AppText.TaskAssignment.InputPatientDataView
typealias AppTextTaskAssignInputExam = AppText.TaskAssignment.InputExaminationDataView
typealias AppTextTaskAssignCompDateField = AppText.TaskAssignment.DateFieldComponent
typealias AppTextTaskAssignCompPatientDisplay = AppText.TaskAssignment.PatientDisplayFieldComponent

extension AppText {
    enum TaskAssignment {
        enum InputPatientDataView {
            static let stepTitles = ["Data Pasien", "Data Sediaan", "Hasil"]
            static let currentStepIndex = 0
            static let picTitle = "Petugas Pemeriksaan"
            static let picPlaceholder = "Pilih Petugas"
            static let patientNamePlaceholder = "Cari nama pasien"
            static let patientNamePlaceholderAutoSelected = "Pasien dipilih otomatis"
            static let patientNameDescription = "Pilih atau masukkan data pasien baru"
            static let patientNameDescriptionAutoSelected = "Pasien telah dipilih dari riwayat"
            static let fillSpecimenDetailsButton = "Isi Detail Sediaan"
        }
        
        enum InputExaminationDataView {
            static let stepTitles = ["Data Pasien", "Data Sediaan", "Hasil"]
            static let currentStepIndex = 1
            static let confirmPopupTitle = "Buat Tugas Pemeriksaan?"
            static let createTaskButton = "Buat Tugas"
            static let reviewAgainButton = "Periksa Kembali"
            static let screeningChoice = "Skrinning"
            static let followUpChoice = "Follow Up"
            static let slideId1Title = AppData.slideIdTitle(1)
            static let slideId1Placeholder = AppData.slideIdPlaceholder("24/11/1/0123A")
            static let slideType1Title = AppData.slideTypeTitle(1)
            static let slideId2Title = AppData.slideIdTitle(2)
            static let slideId2Placeholder = AppData.slideIdPlaceholder("24/11/1/0123B")
            static let slideType2Title = AppData.slideTypeTitle(2)
            static let morningChoice = "Pagi"
            static let anytimeChoice = "Sewaktu"
            static let createTaskFinalButton = "Buat Tugas"
        }
        
        enum DateFieldComponent {
            // This component is mostly UI interaction based, no specific text constants needed
        }
        
        enum PatientDisplayFieldComponent {
            // This component is mostly UI interaction based, no specific text constants needed
        }
    }
}