//
//  AnalysisResultSessionStore.swift
//  Oculab
//

import Foundation

/// Shares one `AnalysisResultPresenter` across analysis-result → FOV album → FOV detail.
@MainActor
final class AnalysisResultSessionStore {
    static let shared = AnalysisResultSessionStore()

    private var presenters: [String: AnalysisResultPresenter] = [:]

    private init() {}

    func register(_ presenter: AnalysisResultPresenter, for examinationId: String) {
        presenters[examinationId.lowercased()] = presenter
    }

    func unregister(examinationId: String) {
        presenters.removeValue(forKey: examinationId.lowercased())
    }

    func presenter(for examinationId: String) -> AnalysisResultPresenter? {
        presenters[examinationId.lowercased()]
    }
}
