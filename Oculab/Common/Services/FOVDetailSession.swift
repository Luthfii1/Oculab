//
//  FOVDetailSession.swift
//  Oculab
//

import Foundation

/// Caches per-FOV presenters so swiping between images does not refetch or reset state.
@MainActor
final class FOVDetailSession: ObservableObject {
    private var presenters: [String: FOVDetailPresenter] = [:]
    private var verifiedFOVIds: Set<String> = []
    let examId: String?

    init(examId: String?) {
        self.examId = examId
    }

    func presenter(for fovId: String) -> FOVDetailPresenter {
        let key = fovId.lowercased()
        if let existing = presenters[key] {
            return existing
        }

        let presenter = FOVDetailPresenter()
        presenter.examId = examId
        presenters[key] = presenter
        return presenter
    }

    func load(fovId: String, markVerified: Bool) async {
        let presenter = presenter(for: fovId)
        let key = fovId.lowercased()

        if presenter.fovDetail == nil, !presenter.isLoading {
            await presenter.fetchData(fovId: fovId)
        }

        if markVerified,
           presenter.isBoundingBoxAvailable,
           !verifiedFOVIds.contains(key)
        {
            await presenter.verifyingFOV(fovId: fovId)
            verifiedFOVIds.insert(key)
        }
    }

    func prefetchAdjacent(fovs: [FOVData], around index: Int) {
        let indices = [index - 1, index + 1].filter { fovs.indices.contains($0) }
        for pageIndex in indices {
            let fovId = fovs[pageIndex].id
            Task {
                await load(fovId: fovId, markVerified: false)
            }
        }
    }

    func clearSelection() {
        presenters.values.forEach { $0.selectedBox = nil }
    }

    func finish() {
        presenters.values.forEach { $0.notifyValidationDataChanged() }
        presenters.removeAll()
        verifiedFOVIds.removeAll()
    }
}
