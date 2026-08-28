//
//  AnalysisTrackingStore.swift
//  Oculab
//

import Foundation

/// Examination IDs the user started analyzing — used for notifications when they leave the screen.
enum AnalysisTrackingStore {
    private static let key = "tracked_analysis_examination_ids"
    private static let resumeKey = "pending_resume_analysis_examination_id"

    static func track(examinationId: String) {
        var ids = trackedIds
        ids.insert(examinationId.lowercased())
        UserDefaults.standard.set(Array(ids), forKey: key)
    }

    static func markPendingResume(examinationId: String) {
        UserDefaults.standard.set(examinationId.lowercased(), forKey: resumeKey)
    }

    static func clearPendingResume() {
        UserDefaults.standard.removeObject(forKey: resumeKey)
    }

    static var pendingResumeExaminationId: String? {
        UserDefaults.standard.string(forKey: resumeKey)
    }

    static func untrack(examinationId: String) {
        var ids = trackedIds
        ids.remove(examinationId.lowercased())
        UserDefaults.standard.set(Array(ids), forKey: key)
    }

    static var trackedIds: Set<String> {
        Set(
            (UserDefaults.standard.stringArray(forKey: key) ?? [])
                .map { $0.lowercased() }
        )
    }

    static func isTracked(_ examinationId: String) -> Bool {
        trackedIds.contains(examinationId.lowercased())
    }

    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: resumeKey)
    }
}
