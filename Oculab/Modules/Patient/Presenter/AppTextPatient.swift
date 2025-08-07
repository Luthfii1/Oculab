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
        }
        
        enum DetailView {
            static let navigationTitle = "Riwayat Pemeriksaan"
            static let patientDataTitle = "Data Pasien"
            static let examinationResultTitle = "Hasil Pemeriksaan"
            static let loadingPatientMessage = AppState.loading("data pasien")
            static let loadingExaminationsMessage = AppState.loading("pemeriksaan")
            static let noExaminationsMessage = AppState.noData("pemeriksaan")
            static let notDeterminedMessage = AppState.notAvailable
        }
        
        enum PatientCardComponent {
            static let birthDatePrefix = "Tanggal Lahir: "
        }
        
        enum PatientFormFieldComponent {
            static let namePlaceholder = "John Doe"
        }
    }
}