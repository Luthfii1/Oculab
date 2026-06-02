//
//  TaskAssignmentDraft.swift
//  Oculab
//

import Foundation

// MARK: - Patient selection (replaces ambiguous String in one field)

enum PatientSelection: Equatable {
    case existing(patientId: String)
    case new(displayName: String)

    var valueForBinding: String {
        switch self {
        case .existing(let id):
            return id
        case .new(let name):
            return name
        }
    }

    var isNewPatient: Bool {
        if case .new = self { return true }
        return false
    }

    var existingPatientId: String? {
        if case .existing(let id) = self { return id }
        return nil
    }

    var newPatientName: String? {
        if case .new(let name) = self { return name }
        return nil
    }

    static func from(bindingValue: String, knownPatientIds: Set<String>) -> PatientSelection? {
        let trimmed = bindingValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if knownPatientIds.contains(trimmed) || TaskAssignmentIdentifiers.isPatientId(trimmed) {
            return .existing(patientId: trimmed)
        }
        return .new(displayName: trimmed)
    }
}

enum TaskAssignmentIdentifiers {
    static func isPatientId(_ value: String) -> Bool {
        UUID(uuidString: value.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }
}
