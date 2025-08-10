//
//  AppTextPatient.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 02/08/25.
//

import Foundation

// MARK: Patient Module Texts
typealias AppTextPatientDetail = AppText.Patient.DetailView
typealias AppTextPatientForm = AppText.Patient.FormView
typealias AppTextPatientList = AppText.Patient.ListView
typealias AppTextPatientCompCard = AppText.Patient.PatientCardComponent
typealias AppTextPatientCompFormField = AppText.Patient.PatientFormFieldComponent

extension AppText {
    enum Patient {
        enum FormView {
            static let newPatientNavigationTitle = "Data Pasien Baru"
            static let editPatientNavigationTitle = "Ubah Data Pasien"
        }
        
        enum ListView {
            static let navigationTitle = "Daftar Pasien"
            static let buttonCreatePatient = AppAction.add("Pasien Baru")
        }
        
        enum DetailView {
            static let navigationTitle = "Riwayat Pemeriksaan"
            static let patientDataTitle = "Data Pasien"
            static let examinationResultTitle = "Hasil Pemeriksaan"
            static let loadingPatientMessage = AppState.loading("data pasien")
            static let loadingExaminationsMessage = AppState.loading("pemeriksaan")
            static let noExaminationsMessage = AppState.noData("pemeriksaan")
            static let notDeterminedMessage = AppState.notDetermined("pemeriksaan")
            static let buttonCreateExamination = AppAction.create("Pemeriksaan")
        }
        
        enum PatientCardComponent {
            static let birthDatePrefix = "Tanggal Lahir: "
            static let buttonCreatePatient = AppAction.add("Pasien Baru")
            static let buttonSavePatient = AppAction.save("Data Pasien")
        }
        
        enum PatientFormFieldComponent {
            static let namePlaceholder = "John Doe"
        }
    }
}
