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
            static let newPatientNavigationTitle = "patient.form.new_patient_navigation_title".localized
            static let editPatientNavigationTitle = "patient.form.edit_patient_navigation_title".localized
        }
        
        enum ListView {
            static let navigationTitle = "patient.list.navigation_title".localized
            static let buttonCreatePatient = AppAction.add("patient.list.button_create_patient".localized)
            static let searchPlaceholder = "patient.list.search_placeholder".localized
            static let emptyListMessage = "patient.list.empty_message".localized
            static let emptyListHint = "patient.list.empty_hint".localized
        }
        
        enum DetailView {
            static let navigationTitle = "patient.detail.navigation_title".localized
            static let patientDataTitle = "patient.detail.patient_data_title".localized
            static let examinationResultTitle = "patient.detail.examination_result_title".localized
            static let loadingPatientMessage = AppState.loading("patient.detail.loading_patient_data".localized)
            static let loadingExaminationsMessage = AppState.loading("patient.detail.loading_examinations_data".localized)
            static let noExaminationsMessage = AppState.noData("patient.detail.no_examinations_data".localized)
            static let notDeterminedMessage = AppState.notDetermined("patient.detail.not_determined_data".localized)
            static let buttonCreateExamination = AppAction.create("patient.detail.button_create_examination".localized)
        }
        
        enum PatientCardComponent {
            static let birthDatePrefix = "patient.card.birth_date_prefix".localized
            static let buttonCreatePatient = AppAction.add("patient.card.button_create_patient".localized)
            static let buttonSavePatient = AppAction.save("patient.card.button_save_patient".localized)
            static let previewName = "patient.card.preview_name".localized
            static let previewBirthDate = "patient.card.preview_birth_date".localized
        }
        
        enum PatientFormFieldComponent {
            static let namePlaceholder = "patient.form_field.name_placeholder".localized
        }
    }
}
