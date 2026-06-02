//
//  TaskAssignmentRepository.swift
//  Oculab
//

import Foundation

/// Network boundary for the task-assignment wizard (patient + examination).
final class TaskAssignmentRepository {
    private let interactor: InputPatientInteractor

    init(interactor: InputPatientInteractor = InputPatientInteractor()) {
        self.interactor = interactor
    }

    func fetchPICs() async throws -> [User] {
        try await interactor.getAllUser()
    }

    func fetchPatients() async throws -> [Patient] {
        try await interactor.getAllPatient()
    }

    func fetchPatient(id: String) async throws -> Patient {
        try await interactor.getPatientById(patientId: id)
    }

    func fetchUser(id: String) async throws -> User {
        try await interactor.getUserById(userId: id)
    }

    func createPatient(_ patient: Patient) async throws -> Patient {
        try await interactor.addNewPatient(patient: patient)
    }

    func createExaminations(
        patientId: String,
        examinations: [ExaminationRequest]
    ) async throws -> ExaminationDataResponse {
        try await interactor.addNewExamination(patientId: patientId, examinations: examinations)
    }

    func isEmptyPatientListError(_ error: Error) -> Bool {
        guard case let NetworkError.apiError(apiResponse, _) = error else { return false }
        return apiResponse.data.errorType == "RESOURCE_NOT_FOUND"
            && apiResponse.data.description == "No patients found"
    }

    /// Ensures the patient exists on the server and returns the canonical record.
    func ensurePatientOnServer(
        draft patient: Patient,
        preferredId: String?
    ) async throws -> Patient {
        let trimmedPreferred = preferredId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? AppValue.empty

        if TaskAssignmentIdentifiers.isPatientId(trimmedPreferred) {
            do {
                return try await fetchPatient(id: trimmedPreferred)
            } catch {
                Logger.warning(
                    "Preferred patient id not found (\(trimmedPreferred)); will create if draft is complete",
                    category: .taskAssignment
                )
            }
        }

        guard !patient.NIK.isEmpty else {
            throw TaskAssignmentFlowError.patientDataIncomplete
        }

        var payload = patient
        if TaskAssignmentIdentifiers.isPatientId(payload.name) {
            payload.name = AppValue.empty
        }

        return try await createPatient(payload)
    }
}

enum TaskAssignmentFlowError: LocalizedError {
    case patientDataIncomplete
    case missingPic
    case missingPatientId

    var errorDescription: String? {
        switch self {
        case .patientDataIncomplete:
            return AppTextTaskAssignInputExam.errorMessageFailedToGetResponse
        case .missingPic:
            return AppTextTaskAssignInputExam.errorMessageFailedToGetResponse
        case .missingPatientId:
            return AppTextTaskAssignInputExam.errorMessageFailedToGetResponse
        }
    }
}
