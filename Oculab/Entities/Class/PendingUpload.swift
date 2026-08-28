//
//  PendingUpload.swift
//  Oculab
//

import Foundation
import SwiftData

enum PendingUploadState: String, Codable {
    case pending
    case uploading
    case failed
}

@Model
final class PendingUpload {
    @Attribute(.unique) var examinationId: String
    var patientId: String
    var localFilePath: String
    var slideId: String
    var stateRaw: String
    var retryCount: Int
    var lastError: String?
    var createdAt: Date

    init(
        examinationId: String,
        patientId: String,
        localFilePath: String,
        slideId: String,
        state: PendingUploadState = .pending,
        retryCount: Int = 0,
        lastError: String? = nil,
        createdAt: Date = .now
    ) {
        self.examinationId = examinationId
        self.patientId = patientId
        self.localFilePath = localFilePath
        self.slideId = slideId
        self.stateRaw = state.rawValue
        self.retryCount = retryCount
        self.lastError = lastError
        self.createdAt = createdAt
    }

    var state: PendingUploadState {
        get { PendingUploadState(rawValue: stateRaw) ?? .pending }
        set { stateRaw = newValue.rawValue }
    }
}
