import Foundation

extension TaskAssignmentFlowCoordinator {
    /// Changing the selection lets the view's selection observer own its lookup.
    /// An unchanged, unresolved selection needs an explicit lookup when returning
    /// after the previous view-owned task was cancelled.
    @MainActor
    func selectDefaultOfficerIfNeeded(user: User) -> String? {
        guard user.role == .LAB, user.businessModel == .B2C else { return nil }
        let officerID = user.id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !officerID.isEmpty else { return nil }

        if selectedPIC.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != officerID.lowercased() {
            selectedPIC = officerID
            return nil
        }
        return pic.id.lowercased() == officerID.lowercased() ? nil : officerID
    }
}
