//
//  TaskAssignmentFlowCoordinator+PatientChoice.swift
//  Oculab
//

import Foundation
import SwiftUI

// MARK: - Typed patient dropdown (PatientSelection)

extension TaskAssignmentFlowCoordinator {
    var hasPatientChoice: Bool {
        patientSelection != nil
    }

    var patientChoiceBinding: Binding<String> {
        Binding(
            get: { self.patientSelection?.valueForBinding ?? AppValue.empty },
            set: { self.updatePatientChoice($0) }
        )
    }

    func updatePatientChoice(_ rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            patientSelection = nil
        } else {
            patientSelection = PatientSelection.from(
                bindingValue: trimmed,
                knownPatientIds: knownPatientIds
            )
        }
        handlePatientSelectionChange()
    }

    @MainActor
    func handlePatientChoiceChange() async {
        guard let selection = patientSelection else { return }

        switch selection {
        case .existing(let patientId):
            await loadExistingPatient(id: patientId, preserveIdentityOnFailure: false)
        case .new(let displayName):
            prepareNewPatientSelection(name: displayName)
        }
    }

    private func syncPatientNameFromSelection() {
        guard let name = patientSelection?.newPatientName else { return }
        patient.name = name
    }
}
