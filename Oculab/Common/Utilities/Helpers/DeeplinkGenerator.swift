//
//  DeeplinkGenerator.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 19/12/24.
//

import Foundation

/// Utility class for generating deeplinks to share app content
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
        return URL(string: "oculab://patient?id=\(patientId)")
    }
    
    /// Generate deeplink for examination detail
    /// - Parameters:
    ///   - examId: The examination ID
    ///   - patientId: The patient ID
    func generateExaminationURL(examId: String, patientId: String) -> URL? {
        return URL(string: "oculab://examination?examId=\(examId)&patientId=\(patientId)")
    }
    
    /// Generate deeplink for examination results
    /// - Parameter examId: The examination ID
    func generateExaminationResultURL(examId: String) -> URL? {
        return URL(string: "oculab://examination/result?examId=\(examId)")
    }
    
    /// Generate deeplink for analysis result
    /// - Parameter examinationId: The examination ID
    func generateAnalysisResultURL(examinationId: String) -> URL? {
        return URL(string: "oculab://analysis?examinationId=\(examinationId)")
    }
    
    /// Generate deeplink for task assignment
    /// - Parameter taskId: The task ID (optional)
    func generateTaskAssignmentURL(taskId: String? = nil) -> URL? {
        if let taskId = taskId {
            return URL(string: "oculab://task?id=\(taskId)")
        } else {
            return URL(string: "oculab://task")
        }
    }
    
    /// Generate deeplink for video record
    /// - Parameter examId: The examination ID (optional)
    func generateVideoRecordURL(examId: String? = nil) -> URL? {
        if let examId = examId {
            return URL(string: "oculab://video?examId=\(examId)")
        } else {
            return URL(string: "oculab://video")
        }
    }
    
    /// Generate deeplink for user management (admin only)
    /// - Parameter userId: The user ID (optional)
    func generateUserManagementURL(userId: String? = nil) -> URL? {
        if let userId = userId {
            return URL(string: "oculab://users?id=\(userId)")
        } else {
            return URL(string: "oculab://users")
        }
    }
    
    /// Generate deeplink for profile settings
    func generateProfileURL() -> URL? {
        return URL(string: "oculab://profile")
    }
    
    /// Generate deeplink for specific profile section
    /// - Parameter section: The profile section to navigate to
    func generateProfileSectionURL(section: ProfileSection) -> URL? {
        return URL(string: "oculab://profile/\(section.rawValue)")
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
        
        shareText += "Buka di Oculab: \(url.absoluteString)"
        
        return shareText
    }
    
    /// Generate share text for examination
    /// - Parameters:
    ///   - examId: The examination ID
    ///   - patientId: The patient ID
    ///   - patientName: The patient's name
    func generateExaminationShareText(examId: String, patientId: String, patientName: String) -> String? {
        guard let url = generateExaminationURL(examId: examId, patientId: patientId) else {
            return nil
        }
        
        return generateShareText(
            url: url,
            title: "Pemeriksaan Pasien",
            description: "Lihat detail pemeriksaan untuk pasien \(patientName)"
        )
    }
    
    /// Generate share text for analysis result
    /// - Parameters:
    ///   - examinationId: The examination ID
    ///   - patientName: The patient's name
    func generateAnalysisResultShareText(examinationId: String, patientName: String) -> String? {
        guard let url = generateAnalysisResultURL(examinationId: examinationId) else {
            return nil
        }
        
        return generateShareText(
            url: url,
            title: "Hasil Analisis",
            description: "Lihat hasil analisis untuk pasien \(patientName)"
        )
    }
    
    /// Generate share text for patient profile
    /// - Parameters:
    ///   - patientId: The patient ID
    ///   - patientName: The patient's name
    func generatePatientShareText(patientId: String, patientName: String) -> String? {
        guard let url = generatePatientURL(patientId: patientId) else {
            return nil
        }
        
        return generateShareText(
            url: url,
            title: "Profil Pasien",
            description: "Lihat profil lengkap pasien \(patientName)"
        )
    }
}

// MARK: - Profile Section Enum
enum ProfileSection: String, CaseIterable {
    case editProfile = "edit"
    case editPassword = "password"
    case security = "security"
    case about = "about"
    
    var displayName: String {
        switch self {
        case .editProfile:
            return "Edit Profil"
        case .editPassword:
            return "Ubah Password"
        case .security:
            return "Keamanan"
        case .about:
            return "Tentang Aplikasi"
        }
    }
}

// MARK: - Deeplink Validation
extension DeeplinkGenerator {
    /// Validate if a URL is a valid Oculab deeplink
    /// - Parameter url: The URL to validate
    /// - Returns: True if valid, false otherwise
    func isValidOculabDeeplink(_ url: URL) -> Bool {
        return url.scheme == "oculab" && !url.host.isNilOrEmpty
    }
    
    /// Extract route information from deeplink URL
    /// - Parameter url: The deeplink URL
    /// - Returns: Route information if valid, nil otherwise
    func extractRouteInfo(from url: URL) -> (host: String, path: String?, parameters: [String: String])? {
        guard isValidOculabDeeplink(url) else { return nil }
        
        let host = url.host ?? ""
        let path = url.path.isEmpty ? nil : String(url.path.dropFirst()) // Remove leading "/"
        
        var parameters: [String: String] = [:]
        if let query = url.query {
            let queryItems = URLComponents(string: "?\(query)")?.queryItems ?? []
            for item in queryItems {
                if let value = item.value {
                    parameters[item.name] = value
                }
            }
        }
        
        return (host: host, path: path, parameters: parameters)
    }
}

// MARK: - String Extension for Utility
private extension String? {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}
