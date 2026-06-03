//
//  AppNotificationDelegate.swift
//  Oculab
//

import Foundation
import UIKit
import UserNotifications

final class AppNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let examinationId = response.notification.request.content.userInfo[
            ExaminationNotificationUserInfoKey.examinationId
        ] as? String else {
            return
        }

        await MainActor.run {
            Router.shared.navigateTo(.analysisResult(examinationId: examinationId))
        }
    }
}
