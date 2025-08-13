//
//  ValidationFieldName.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 13/08/2025.
//

import Foundation

/// Enum representing all possible field names for form validation
/// This ensures type safety and prevents typos in field name strings
enum ValidationFieldName: String, CaseIterable {
    
    // MARK: - Authentication Fields
    case loginEmail = "login_email"
    case loginPassword = "login_password"
    
    // MARK: - User Management Fields
    case userName = "user_name"
    case userEmail = "user_email"
    case userRole = "user_role"
    case userPhone = "user_phone"
    
    // MARK: - Patient Fields
    case patientName = "patient_name"
    case patientNIK = "patient_nik"
    case patientBPJS = "patient_bpjs"
    case patientPhone = "patient_phone"
    case patientAddress = "patient_address"
    case patientDateOfBirth = "patient_date_of_birth"
    case patientAge = "patient_age"
    case patientGender = "patient_gender"
    
    // MARK: - Medical Fields
    case medicalRecord = "medical_record"
    case medicalRecordNumber = "medical_record_number"
    case diagnosis = "diagnosis"
    case symptoms = "symptoms"
    case allergies = "allergies"
    case medications = "medications"
    case medicalHistory = "medical_history"
    
    // MARK: - Password Fields
    case currentPassword = "current_password"
    case newPassword = "new_password"
    case confirmPassword = "confirm_password"
    case oldPassword = "old_password"
    
    // MARK: - Examination Fields
    case examinationDate = "examination_date"
    case examinationType = "examination_type"
    case examinationNotes = "examination_notes"
    case examinationResult = "examination_result"
    
    // MARK: - Task Assignment Fields
    case taskTitle = "task_title"
    case taskDescription = "task_description"
    case taskAssignee = "task_assignee"
    case taskDueDate = "task_due_date"
    case taskPriority = "task_priority"
    
    // MARK: - Video Recording Fields
    case videoTitle = "video_title"
    case videoDescription = "video_description"
    case videoDuration = "video_duration"
    case videoQuality = "video_quality"
    
    // MARK: - Profile Fields
    case profileName = "profile_name"
    case profileEmail = "profile_email"
    case profilePhone = "profile_phone"
    case profileAddress = "profile_address"
    
    // MARK: - Analysis Fields
    case analysisTitle = "analysis_title"
    case analysisDescription = "analysis_description"
    case analysisType = "analysis_type"
    case analysisResults = "analysis_results"
    
    // MARK: - Bounding Box Validation Fields
    case boundingBoxCoordinates = "bounding_box_coordinates"
    case boundingBoxAccuracy = "bounding_box_accuracy"
    case boundingBoxValidation = "bounding_box_validation"
    
    // MARK: - Generic Fields
    case title = "title"
    case description = "description"
    case notes = "notes"
    case comments = "comments"
    case dateOfBirth = "date_of_birth"
    case age = "age"
    case gender = "gender"
    case address = "address"
    case phone = "phone"
    case email = "email"
    case name = "name"
    case required = "required"
    
    // MARK: - Helper Properties
    
    /// The string value of the field name
    var fieldName: String {
        return self.rawValue
    }
    
    /// Human-readable display name for the field
    var displayName: String {
        switch self {
        // Authentication
        case .loginEmail: return "Email"
        case .loginPassword: return "Password"
            
        // User Management
        case .userName: return "User Name"
        case .userEmail: return "User Email"
        case .userRole: return "User Role"
        case .userPhone: return "User Phone"
            
        // Patient
        case .patientName: return "Patient Name"
        case .patientNIK: return "NIK"
        case .patientBPJS: return "BPJS Number"
        case .patientPhone: return "Patient Phone"
        case .patientAddress: return "Patient Address"
        case .patientDateOfBirth: return "Date of Birth"
        case .patientAge: return "Age"
        case .patientGender: return "Gender"
            
        // Medical
        case .medicalRecord, .medicalRecordNumber: return "Medical Record Number"
        case .diagnosis: return "Diagnosis"
        case .symptoms: return "Symptoms"
        case .allergies: return "Allergies"
        case .medications: return "Medications"
        case .medicalHistory: return "Medical History"
            
        // Password
        case .currentPassword: return "Current Password"
        case .newPassword: return "New Password"
        case .confirmPassword: return "Confirm Password"
        case .oldPassword: return "Old Password"
            
        // Examination
        case .examinationDate: return "Examination Date"
        case .examinationType: return "Examination Type"
        case .examinationNotes: return "Examination Notes"
        case .examinationResult: return "Examination Result"
            
        // Task Assignment
        case .taskTitle: return "Task Title"
        case .taskDescription: return "Task Description"
        case .taskAssignee: return "Assignee"
        case .taskDueDate: return "Due Date"
        case .taskPriority: return "Priority"
            
        // Video Recording
        case .videoTitle: return "Video Title"
        case .videoDescription: return "Video Description"
        case .videoDuration: return "Video Duration"
        case .videoQuality: return "Video Quality"
            
        // Profile
        case .profileName: return "Profile Name"
        case .profileEmail: return "Profile Email"
        case .profilePhone: return "Profile Phone"
        case .profileAddress: return "Profile Address"
            
        // Analysis
        case .analysisTitle: return "Analysis Title"
        case .analysisDescription: return "Analysis Description"
        case .analysisType: return "Analysis Type"
        case .analysisResults: return "Analysis Results"
            
        // Bounding Box
        case .boundingBoxCoordinates: return "Bounding Box Coordinates"
        case .boundingBoxAccuracy: return "Bounding Box Accuracy"
        case .boundingBoxValidation: return "Bounding Box Validation"
            
        // Generic
        case .title: return "Title"
        case .description: return "Description"
        case .notes: return "Notes"
        case .comments: return "Comments"
        case .dateOfBirth: return "Date of Birth"
        case .age: return "Age"
        case .gender: return "Gender"
        case .address: return "Address"
        case .phone: return "Phone"
        case .email: return "Email"
        case .name: return "Name"
        case .required: return "Required Field"
        }
    }
    
    /// Category grouping for the field
    var category: ValidationFieldCategory {
        switch self {
        case .loginEmail, .loginPassword:
            return .authentication
        case .userName, .userEmail, .userRole, .userPhone:
            return .userManagement
        case .patientName, .patientNIK, .patientBPJS, .patientPhone, .patientAddress, .patientDateOfBirth, .patientAge, .patientGender:
            return .patient
        case .medicalRecord, .medicalRecordNumber, .diagnosis, .symptoms, .allergies, .medications, .medicalHistory:
            return .medical
        case .currentPassword, .newPassword, .confirmPassword, .oldPassword:
            return .password
        case .examinationDate, .examinationType, .examinationNotes, .examinationResult:
            return .examination
        case .taskTitle, .taskDescription, .taskAssignee, .taskDueDate, .taskPriority:
            return .taskAssignment
        case .videoTitle, .videoDescription, .videoDuration, .videoQuality:
            return .videoRecording
        case .profileName, .profileEmail, .profilePhone, .profileAddress:
            return .profile
        case .analysisTitle, .analysisDescription, .analysisType, .analysisResults:
            return .analysis
        case .boundingBoxCoordinates, .boundingBoxAccuracy, .boundingBoxValidation:
            return .boundingBox
        case .title, .description, .notes, .comments, .dateOfBirth, .age, .gender, .address, .phone, .email, .name, .required:
            return .generic
        }
    }
}

/// Categories for organizing validation fields
enum ValidationFieldCategory: String, CaseIterable {
    case authentication = "Authentication"
    case userManagement = "User Management"
    case patient = "Patient"
    case medical = "Medical"
    case password = "Password"
    case examination = "Examination"
    case taskAssignment = "Task Assignment"
    case videoRecording = "Video Recording"
    case profile = "Profile"
    case analysis = "Analysis"
    case boundingBox = "Bounding Box"
    case generic = "Generic"
}

// MARK: - Extensions for Easy Access

extension ValidationFieldName {
    
    /// Get all field names for a specific category
    static func fields(for category: ValidationFieldCategory) -> [ValidationFieldName] {
        return ValidationFieldName.allCases.filter { $0.category == category }
    }
    
    /// Check if field is related to medical data
    var isMedicalField: Bool {
        return category == .medical || category == .patient
    }
    
    /// Check if field is related to authentication
    var isAuthenticationField: Bool {
        return category == .authentication || category == .password
    }
    
    /// Check if field requires special validation rules
    var requiresSpecialValidation: Bool {
        switch self {
        case .patientNIK, .patientBPJS, .medicalRecord, .medicalRecordNumber:
            return true
        default:
            return false
        }
    }
}
