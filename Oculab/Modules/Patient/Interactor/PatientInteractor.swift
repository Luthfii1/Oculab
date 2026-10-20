//
//  PatientInteractor.swift
//  Oculab
//
//  Created by Risa on 30/05/25.
//

import Foundation

@MainActor
class PatientInteractor: ObservableObject {
    // MARK: - Dependencies
    private let networkService: NetworkServiceProtocol

    // MARK: - API Endpoints
    private struct APIEndpoints {
        static let getAllPatients = API.BE + "/patient/get-all-patients/"
        static let getPatientById = API.BE + "/patient/get-patient-by-id/"
        static let getAllExamByPatientId = API.BE + "/examination/get-examination-card-by-patient/"
        static let createPatient = API.BE + "/patient/create-new-patient/"
        static let updatePatient = API.BE + "/patient/update-data/"
    }
    
    // MARK: - Initialization
    init(networkService: NetworkServiceProtocol = DependencyInjection.shared.networkService) {
        self.networkService = networkService
    }
    
    // MARK: - Patient Data Operations
    func getAllPatient() async throws -> [Patient] {
        let session = try sessionSnapshot()
        let headers = try AuthSessionManager.authorizationHeaders()
        let userId = session.ownerUserId
        
        let response: APIResponse<[Patient]> = try await ClinicalRequestContext.withSession(session) {
            try await networkService
                .get(urlString: APIEndpoints.getAllPatients + userId.lowercased(), headers: headers)
        }

        try requireCurrentSession(session)
        Logger.info("Successfully fetched all patients", category: .patient)
        return response.data
    }
    
    func getPatientById(patientId: String) async throws -> Patient {
        let session = try sessionSnapshot()
        let headers = try AuthSessionManager.authorizationHeaders()
        let response: APIResponse<Patient> = try await ClinicalRequestContext.withSession(session) {
            try await networkService
                .get(urlString: APIEndpoints.getPatientById + patientId.lowercased(), headers: headers)
        }

        try requireCurrentSession(session)
        guard response.data.id.lowercased() == patientId.lowercased() else { throw URLError(.cannotParseResponse) }
        Logger.info("Successfully fetched patient", category: .patient)
        return response.data
    }
    
    func getAllExamByPatientId(patientId: String) async throws -> [ExaminationResultCardData] {
        let session = try sessionSnapshot()
        let headers = try AuthSessionManager.authorizationHeaders()
        let response: APIResponse<[ExaminationResultCardData]> = try await ClinicalRequestContext.withSession(session) {
            try await networkService
                .get(urlString: APIEndpoints.getAllExamByPatientId + patientId, headers: headers)
        }

        try requireCurrentSession(session)
        Logger.info("Successfully fetched examinations for patient", category: .patient)
        return response.data
    }
    
    func addNewPatient(patient: Patient) async throws -> Patient {
        let session = try sessionSnapshot()
        let headers = try AuthSessionManager.authorizationHeaders()
        let adminUserId = session.ownerUserId
        
        let response: APIResponse<Patient> = try await ClinicalRequestContext.withSession(session) {
            try await networkService.post(
                urlString: APIEndpoints.createPatient + adminUserId.lowercased(),
                headers: headers,
                body: patient
            )
        }

        try requireCurrentSession(session)
        Logger.info("Successfully created new patient", category: .patient)
        return response.data
    }
    
    func updatePatient(patient: Patient, patientId: String) async throws -> Patient {
        let session = try sessionSnapshot()
        let headers = try AuthSessionManager.authorizationHeaders()
        let response: APIResponse<Patient> = try await ClinicalRequestContext.withSession(session) {
            try await networkService.update(
                urlString: APIEndpoints.updatePatient + patientId.lowercased(),
                headers: headers,
                body: PatientUpdateBody(patient: patient)
            )
        }

        try requireCurrentSession(session)
        guard response.data.id.lowercased() == patientId.lowercased() else { throw URLError(.cannotParseResponse) }
        Logger.info("Successfully updated patient", category: .patient)
        return response.data
    }
}

// MARK: - Helper Methods
extension PatientInteractor {
    private func sessionSnapshot() throws -> UploadQueueSession {
        guard let session = AuthSessionManager.uploadQueueSession else { throw URLError(.userAuthenticationRequired) }
        try Task.checkCancellation()
        return session
    }

    private func requireCurrentSession(_ expected: UploadQueueSession) throws {
        try Task.checkCancellation()
        guard expected == AuthSessionManager.uploadQueueSession else { throw CancellationError() }
    }
}

/// PATCH-like identifier semantics on the existing PUT endpoint: a deliberate
/// cleared field is null, rather than silently omitted by encodeIfPresent.
private struct PatientUpdateBody: Encodable {
    let patient: Patient
    private enum Keys: String, CodingKey { case BPJS, medicalRecordNumber }
    func encode(to encoder: Encoder) throws {
        try patient.encode(to: encoder)
        var values = encoder.container(keyedBy: Keys.self)
        if patient.BPJS == nil { try values.encodeNil(forKey: .BPJS) }
        if patient.medicalRecordNumber == nil { try values.encodeNil(forKey: .medicalRecordNumber) }
    }
}
