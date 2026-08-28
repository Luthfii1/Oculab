//
//  AnalysisProgressUpdate.swift
//  Oculab
//

import Foundation

struct AnalysisProgressUpdate: Equatable, Decodable {
    let examId: String
    let status: String
    let progress: Int
    let message: String?
    let statusExamination: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case examId
        case status
        case progress
        case message
        case statusExamination
        case updatedAt
    }

    var isReadyForValidation: Bool {
        status == "need_validation"
            || statusExamination?.uppercased() == StatusType.NEEDVALIDATION.rawValue
    }

    var isFailed: Bool {
        status == "failed"
    }

    var isQueued: Bool {
        status == "queued"
    }

    var progressFraction: Double {
        Double(min(100, max(0, progress))) / 100.0
    }
}
