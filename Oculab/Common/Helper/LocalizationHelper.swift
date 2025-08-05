//
//  LocalizationHelper.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 05/08/25.
//

import Foundation

// MARK: - Localization Helper
extension String {
    /// Returns the localized string for the current key
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Returns the localized string with arguments
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}

// MARK: - Localization Keys
enum LocalizationKey {
    // MARK: - Common
    enum Common {
        static let ok = "common.ok"
        static let cancel = "common.cancel"
        static let close = "common.close"
        static let save = "common.save"
        static let delete = "common.delete"
        static let edit = "common.edit"
        static let next = "common.next"
        static let back = "common.back"
        static let error = "common.error"
    }
    
    // MARK: - Authentication
    enum Auth {
        enum Login {
            static let title = "auth.login.title"
            static let email = "auth.login.email"
            static let emailPlaceholder = "auth.login.email.placeholder"
            static let password = "auth.login.password"
            static let passwordPlaceholder = "auth.login.password.placeholder"
            static let button = "auth.login.button"
            static let notRegistered = "auth.login.not_registered"
            static let registerFacility = "auth.login.register_facility"
        }
    }
    
    // MARK: - Profile
    enum Profile {
        static let title = "profile.title"
        static let accountInfo = "profile.account_info"
        static let email = "profile.email"
        static let role = "profile.role"
        static let jobTitle = "profile.job_title"
        static let jobTitleValue = "profile.job_title.value"
        static let healthFacility = "profile.health_facility"
        static let accountManagement = "profile.account_management"
        static let editPassword = "profile.edit_password"
        static let editPin = "profile.edit_pin"
        static let faceId = "profile.face_id"
        static let privacyPolicy = "profile.privacy_policy"
        static let logout = "profile.logout"
    }
    
    // MARK: - Examination
    enum Exam {
        static let new = "exam.new"
        static let detailTitle = "exam.detail.title"
        static let patientData = "exam.patient_data"
        static let resultTitle = "exam.result.title"
        static let interpretationStaff = "exam.interpretation.staff"
        static let interpretationSystem = "exam.interpretation.system"
        static let notAvailable = "exam.not_available"
        static let viewPdf = "exam.view_pdf"
        static let reportSitb = "exam.report_sitb"
        
        enum Patient {
            static let name = "exam.patient.name"
            static let nik = "exam.patient.nik"
            static let dob = "exam.patient.dob"
            static let sex = "exam.patient.sex"
            static let bpjs = "exam.patient.bpjs"
        }
    }
    
    // MARK: - Patient
    enum Patient {
        static let new = "patient.new"
        static let edit = "patient.edit"
        static let addNew = "patient.add_new"
        static let save = "patient.save"
        static let searchPlaceholder = "patient.search.placeholder"
        static let noResults = "patient.no_results"
        static let clearSearch = "patient.clear_search"
        static let history = "patient.history"
        static let newExamination = "patient.new_examination"
        static let noExaminations = "patient.no_examinations"
    }
    
    // MARK: - Video Record
    enum Video {
        static let instructionTitle = "video.instruction.title"
        static let preparation = "video.preparation"
        static let recordingInstruction = "video.recording_instruction"
        static let startRecording = "video.start_recording"
        static let save = "video.save"
        static let retake = "video.retake"
        static let takeImage = "video.take_image"
        static let preview = "video.preview"
    }
}

// MARK: - Convenient Localization Functions
func L(_ key: String) -> String {
    return key.localized
}

func L(_ key: String, _ arguments: CVarArg...) -> String {
    return key.localized(with: arguments)
}
