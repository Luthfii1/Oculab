//
//  AnalysisTrackingStore.swift
//  Oculab
//

import Foundation

/// Examination IDs the user started analyzing — used for notifications when they leave the screen.
enum AnalysisTrackingStore {
    private static let key = "tracked_analysis_examination_ids"

    static func track(examinationId: String) {
        var ids = trackedIds
        ids.insert(examinationId.lowercased())
        UserDefaults.standard.set(Array(ids), forKey: key)
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
}
