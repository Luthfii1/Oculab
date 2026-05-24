//
//  ShareHelper.swift
//  Oculab
//
//  Created by Assistant on 19/12/24.
//

import SwiftUI
import UIKit

/// Helper class for sharing content within the app
class ShareHelper {
    static let shared = ShareHelper()
    
    private init() {}
    
    /// Present a share sheet with the provided content
    /// - Parameters:
    ///   - items: Array of items to share (URLs, text, etc.)
    ///   - excludedActivityTypes: Activity types to exclude from the share sheet
    func shareContent(
        items: [Any],
        excludedActivityTypes: [UIActivity.ActivityType]? = nil
    ) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        activityViewController.excludedActivityTypes = excludedActivityTypes
        
        // For iPad compatibility
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = rootViewController.view
            popoverController.sourceRect = CGRect(
                x: rootViewController.view.bounds.midX,
                y: rootViewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }
        
        rootViewController.present(activityViewController, animated: true)
    }
    
    /// Share a deeplink URL with optional title and description
    /// - Parameters:
    ///   - url: The deeplink URL to share
    ///   - title: Optional title for the shared content
    ///   - description: Optional description for the shared content
    func shareDeeplink(url: URL, title: String? = nil, description: String? = nil) {
        let shareText = DeeplinkGenerator.shared.generateShareText(
            url: url,
            title: title,
            description: description
        )
        
        shareContent(items: [shareText, url])
    }
    
    /// Share examination details
    /// - Parameters:
    ///   - examId: The examination ID
    ///   - patientId: The patient ID
    ///   - patientName: The patient's name
    func shareExamination(examId: String, patientId: String, patientName: String) {
        guard let shareText = DeeplinkGenerator.shared.generateExaminationShareText(
            examId: examId,
            patientId: patientId,
            patientName: patientName
        ) else { return }
        
        shareContent(items: [shareText])
    }
    
    /// Share analysis result
    /// - Parameters:
    ///   - examinationId: The examination ID
    ///   - patientName: The patient's name
    func shareAnalysisResult(examinationId: String, patientName: String) {
        guard let shareText = DeeplinkGenerator.shared.generateAnalysisResultShareText(
            examinationId: examinationId,
            patientName: patientName
        ) else { return }
        
        shareContent(items: [shareText])
    }
    
    /// Share patient profile
    /// - Parameters:
    ///   - patientId: The patient ID
    ///   - patientName: The patient's name
    func sharePatient(patientId: String, patientName: String) {
        guard let shareText = DeeplinkGenerator.shared.generatePatientShareText(
            patientId: patientId,
            patientName: patientName
        ) else { return }
        
        shareContent(items: [shareText])
    }
    
    /// Copy text to clipboard
    /// - Parameter text: The text to copy
    func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }
    
    /// Copy deeplink URL to clipboard
    /// - Parameter url: The URL to copy
    func copyDeeplinkToClipboard(_ url: URL) {
        copyToClipboard(url.absoluteString)
    }
}

// MARK: - SwiftUI View Extensions
extension View {
    /// Add a share button that presents a share sheet
    /// - Parameters:
    ///   - items: Items to share
    ///   - buttonTitle: Title for the share button
    ///   - excludedActivityTypes: Activity types to exclude
    func shareButton(
        items: [Any],
        buttonTitle: String = "Bagikan",
        excludedActivityTypes: [UIActivity.ActivityType]? = nil
    ) -> some View {
        Button(buttonTitle) {
            ShareHelper.shared.shareContent(
                items: items,
                excludedActivityTypes: excludedActivityTypes
            )
        }
    }
    
    /// Add a deeplink share button
    /// - Parameters:
    ///   - url: The deeplink URL to share
    ///   - title: Optional title for the shared content
    ///   - description: Optional description for the shared content
    ///   - buttonTitle: Title for the share button
    func deeplinkShareButton(
        url: URL,
        title: String? = nil,
        description: String? = nil,
        buttonTitle: String = "Bagikan"
    ) -> some View {
        Button(buttonTitle) {
            ShareHelper.shared.shareDeeplink(
                url: url,
                title: title,
                description: description
            )
        }
    }
    
    /// Add examination share functionality
    /// - Parameters:
    ///   - examId: The examination ID
    ///   - patientId: The patient ID
    ///   - patientName: The patient's name
    ///   - buttonTitle: Title for the share button
    func examinationShareButton(
        examId: String,
        patientId: String,
        patientName: String,
        buttonTitle: String = "Bagikan Pemeriksaan"
    ) -> some View {
        Button(buttonTitle) {
            ShareHelper.shared.shareExamination(
                examId: examId,
                patientId: patientId,
                patientName: patientName
            )
        }
    }
    
    /// Add analysis result share functionality
    /// - Parameters:
    ///   - examinationId: The examination ID
    ///   - patientName: The patient's name
    ///   - buttonTitle: Title for the share button
    func analysisResultShareButton(
        examinationId: String,
        patientName: String,
        buttonTitle: String = "Bagikan Hasil"
    ) -> some View {
        Button(buttonTitle) {
            ShareHelper.shared.shareAnalysisResult(
                examinationId: examinationId,
                patientName: patientName
            )
        }
    }
    
    /// Add patient profile share functionality
    /// - Parameters:
    ///   - patientId: The patient ID
    ///   - patientName: The patient's name
    ///   - buttonTitle: Title for the share button
    func patientShareButton(
        patientId: String,
        patientName: String,
        buttonTitle: String = "Bagikan Pasien"
    ) -> some View {
        Button(buttonTitle) {
            ShareHelper.shared.sharePatient(
                patientId: patientId,
                patientName: patientName
            )
        }
    }
}
