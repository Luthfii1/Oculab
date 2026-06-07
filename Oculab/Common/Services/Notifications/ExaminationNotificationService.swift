//
//  ExaminationNotificationService.swift
//  Oculab
//

import Foundation
import UIKit
import UserNotifications

extension Notification.Name {
    static let examinationAnalysisReady = Notification.Name("examinationAnalysisReady")
    static let examinationAnalysisProgress = Notification.Name("examinationAnalysisProgress")
    static let fovVerificationUpdated = Notification.Name("fovVerificationUpdated")
}

final class ExaminationNotificationService {
    static let shared = ExaminationNotificationService()

    private init() {}

    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        guard settings.authorizationStatus == .notDetermined else { return }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            Logger.info("Notification permission granted: \(granted)", category: .examination)
        } catch {
            Logger.warning("Notification permission request failed: \(error)", category: .examination)
        }
    }

    func notifyAnalysisReady(examinationId: String) {
        NotificationCenter.default.post(
            name: .examinationAnalysisReady,
            object: nil,
            userInfo: [ExaminationNotificationUserInfoKey.examinationId: examinationId.lowercased()]
        )

        guard UIApplication.shared.applicationState != .active else { return }

        let content = UNMutableNotificationContent()
        content.title = AppTextExamProgress.notificationReadyTitle
        content.body = AppTextExamProgress.notificationReadyBody
        content.sound = .default
        content.userInfo = [
            ExaminationNotificationUserInfoKey.examinationId: examinationId.lowercased()
        ]

        let request = UNNotificationRequest(
            identifier: "analysis-ready-\(examinationId.lowercased())",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                Logger.error("Failed to schedule analysis notification: \(error)", category: .examination)
            }
        }

    }
}

enum ExaminationNotificationUserInfoKey {
    static let examinationId = "examinationId"
}
