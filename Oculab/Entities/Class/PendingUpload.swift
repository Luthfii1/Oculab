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
    /// Nil on existing installs: never infer an owner from the next login.
    var ownerUserId: String? = nil
    var submissionId: String? = nil
    var videoSHA256: String? = nil
    var needsReconciliation: Bool = false
    var nextAttemptAt: Date? = nil
    var transientRetryCount: Int = 0
    var stopReasonRaw: String? = nil
    var hasSubmissionConflict: Bool = false
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
        ownerUserId: String? = nil,
        state: PendingUploadState = .pending,
        retryCount: Int = 0,
        lastError: String? = nil,
        createdAt: Date = .now
    ) {
        self.examinationId = examinationId
        self.patientId = patientId
        self.localFilePath = localFilePath
        self.slideId = slideId
        self.ownerUserId = ownerUserId?.lowercased()
        self.stateRaw = state.rawValue
        self.retryCount = retryCount
        self.lastError = lastError
        self.createdAt = createdAt
    }

    var stopReason: PendingUploadStopReason? {
        get { stopReasonRaw.flatMap(PendingUploadStopReason.init(rawValue:)) }
        set { stopReasonRaw = newValue?.rawValue }
    }

    var state: PendingUploadState {
        get { PendingUploadState(rawValue: stateRaw) ?? .pending }
        set { stateRaw = newValue.rawValue }
    }
}

enum PendingUploadStopReason: String {
    case authentication
    case permanent
    case replaceVideo
    case exhausted
    case serviceUpdate
}
