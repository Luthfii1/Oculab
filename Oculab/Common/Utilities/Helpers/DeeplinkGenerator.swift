//
//  DeeplinkGenerator.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 19/12/24.
//

import Foundation

/// Utility class for generating deeplinks to share app content.
/// Hosts MUST match `DeeplinkType` raw values so `RouteFinder` can parse them.
class DeeplinkGenerator {
    static let shared = DeeplinkGenerator()
    
    private init() {}
    
    // MARK: - URL Generation Methods
    
    /// Generate deeplink for home page
    func generateHomeURL() -> URL? {
        return URL(string: "oculab://home")
    }
    
    /// Generate deeplink for patient profile
    /// - Parameter patientId: The ID of the patient
    func generatePatientURL(patientId: String) -> URL? {
        return URL(string: "oculab://patient-detail?patientId=\(patientId)")
    }
    
    /// Generate deeplink for examination detail
    /// - Parameters:
    ///   - examId: The examination ID
    ///   - patientId: The patient ID
    func generateExaminationURL(examId: String, patientId: String) -> URL? {
        return URL(string: "oculab://exam-detail?examId=\(examId)&patientId=\(patientId)")
    }
    
    /// Generate deeplink for examination results (saved / finished)
    /// - Parameter examId: The examination ID
    func generateExaminationResultURL(examId: String) -> URL? {
        return URL(string: "oculab://analysis-result?examinationId=\(examId)")
    }
    
    /// Generate deeplink for analysis result
    /// - Parameter examinationId: The examination ID
    func generateAnalysisResultURL(examinationId: String) -> URL? {
        return URL(string: "oculab://analysis-result?examinationId=\(examinationId)")
    }
    
    /// Generate deeplink for new exam / task assignment
    /// - Parameter taskId: Unused legacy param; prefer patientId/picId on new-exam
    func generateTaskAssignmentURL(taskId: String? = nil) -> URL? {
        if let taskId = taskId, !taskId.isEmpty {
            return URL(string: "oculab://new-exam?patientId=\(taskId)")
        }
        return URL(string: "oculab://new-exam")
    }
    
    /// Generate deeplink for video record
    /// - Parameter examId: Used as slideId for the video-record route
    func generateVideoRecordURL(examId: String? = nil) -> URL? {
        if let examId = examId {
            return URL(string: "oculab://video-record?slideId=\(examId)")
        }
        return URL(string: "oculab://video-record")
    }
    
    /// Generate deeplink for user management (admin only)
    /// - Parameter userId: Unused; account management is a list screen
    func generateUserManagementURL(userId: String? = nil) -> URL? {
        _ = userId
        return URL(string: "oculab://account-management")
    }
    
    /// Generate deeplink for profile settings
    func generateProfileURL() -> URL? {
        return URL(string: "oculab://profile")
    }
    
    /// Generate deeplink for specific profile section
    /// - Parameter section: The profile section to navigate to
    func generateProfileSectionURL(section: ProfileSection) -> URL? {
        return URL(string: "oculab://profile?section=\(section.rawValue)")
    }
    
    // MARK: - Share URL Methods
    
    /// Generate a shareable URL with user-friendly text
    /// - Parameters:
    ///   - url: The deeplink URL to share
    ///   - title: Optional title for the shared content
    ///   - description: Optional description for the shared content
    /// - Returns: A formatted string ready for sharing
    func generateShareText(url: URL, title: String? = nil, description: String? = nil) -> String {
        var shareText = ""
        
        if let title = title {
            shareText += "\(title)\n\n"
        }
        
        if let description = description {
            shareText += "\(description)\n\n"
        }
        
        shareText += "Open in Oculab: \(url.absoluteString)"
        
        return shareText
    }
}

// MARK: - Profile Section Enum
enum ProfileSection: String, CaseIterable {
    case account = "account"
    case security = "security"
    case notifications = "notifications"
    case about = "about"
    
    var displayName: String {
        switch self {
        case .account: return "Account"
        case .security: return "Security"
        case .notifications: return "Notifications"
        case .about: return "About"
        }
    }
}
