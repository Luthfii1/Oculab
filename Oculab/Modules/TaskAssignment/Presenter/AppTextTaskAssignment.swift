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
            static let stepTitles = ["task_assignment.input_patient.step_title_patient".localized, 
                                   "task_assignment.input_patient.step_title_specimen".localized, 
                                   "task_assignment.input_patient.step_title_results".localized]
            static let currentStepIndex = 0
            static let picTitle = "task_assignment.input_patient.pic_title".localized
            static let patientNamePlaceholderAutoSelected = "task_assignment.input_patient.patient_name_placeholder_auto_selected".localized
            static let patientNameDescription = "task_assignment.input_patient.patient_name_description".localized
            static let patientNameDescriptionAutoSelected = "task_assignment.input_patient.patient_name_description_auto_selected".localized
            static let fillSpecimenDetailsButton = "task_assignment.input_patient.fill_specimen_details_button".localized
            static let selectPIC = AppForm.select("task_assignment.input_patient.select_pic_data".localized)
            static let patientNamePlaceholder = "task_assignment.input_patient.patient_name_placeholder".localized
            static let navigationTitle = "task_assignment.input_patient.navigation_title".localized
        }
        
        enum InputExaminationDataView {
            static let stepTitles = ["task_assignment.input_exam.step_title_patient".localized, 
                                   "task_assignment.input_exam.step_title_specimen".localized, 
                                   "task_assignment.input_exam.step_title_results".localized]
            static let currentStepIndex = 1
            static let confirmPopupTitle = "task_assignment.input_exam.confirm_popup_title".localized
            static let createTaskButton = "task_assignment.input_exam.create_task_button".localized
            static let reviewAgainButton = "task_assignment.input_exam.review_again_button".localized
            static let screeningChoice = "task_assignment.input_exam.screening_choice".localized
            static let followUpChoice = "task_assignment.input_exam.follow_up_choice".localized
            static let slideId1Title = AppData.slideIdTitle(1)
            static let slideId1Placeholder = AppData.slideIdPlaceholder("24/11/1/0123A")
            static let slideType1Title = AppData.slideTypeTitle(1)
            static let slideId2Title = AppData.slideIdTitle(2)
            static let slideId2Placeholder = AppData.slideIdPlaceholder("24/11/1/0123B")
            static let slideType2Title = AppData.slideTypeTitle(2)
            static let morningChoice = "task_assignment.input_exam.morning_choice".localized
            static let anytimeChoice = "task_assignment.input_exam.anytime_choice".localized
            static let createTaskFinalButton = "task_assignment.input_exam.create_task_final_button".localized
            static let navigationTitle = "task_assignment.input_exam.navigation_title".localized
            static let warningFirstExamShouldBeFilled = "task_assignment.input_exam.warning_first_exam_should_be_filled".localized
            static let warningSecondExamShouldBeFilled = "task_assignment.input_exam.warning_second_exam_should_be_filled".localized
            static let warningSlideIDsMustBeDifferent = "task_assignment.input_exam.warning_slide_ids_must_be_different".localized
            static let warningExaminationMustBeFilled = "task_assignment.input_exam.warning_examination_must_be_filled".localized
            static let errorMessageFailedToGetResponse = "task_assignment.input_exam.error_message_failed_to_get_response".localized
            static let errorMessageNotAllExamsCreated = "task_assignment.input_exam.error_message_not_all_exams_created".localized
            static let errorMessageExamsContainInvalidData = "task_assignment.input_exam.error_message_exams_contain_invalid_data".localized

            static let addSlide2Button = "task_assignment.input_exam.add_slide2_button".localized
            static let removeSlide2Button = "task_assignment.input_exam.remove_slide2_button".localized

            static func examinationDescription(patientName: String, picName: String) -> String {
                return "task_assignment.input_exam.examination_description".localized(with: [patientName, picName])
            }
        }
        
        enum DateFieldComponent {
            // This component is mostly UI interaction based, no specific text constants needed
        }
        
        enum PatientDisplayFieldComponent {
            // This component is mostly UI interaction based, no specific text constants needed
        }
    }
}
