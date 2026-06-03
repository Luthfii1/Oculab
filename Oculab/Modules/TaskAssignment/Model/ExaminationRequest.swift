//
//  ExaminationRequest.swift
//  Oculab
//

import Foundation

struct ExaminationRequest: Encodable {
    var goal: ExamGoalType?
    var preparationType: ExamPreparationType?
    var slideId: String?
    var examinationDate: Date?
    var PIC: String?
    var DPJP: String?
    var examinationPlanDate: Date?

    enum CodingKeys: CodingKey {
        case goal
        case preparationType
        case slideId
        case examinationDate
        case PIC
        case DPJP
        case examinationPlanDate
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(goal, forKey: .goal)
        try container.encode(preparationType, forKey: .preparationType)
        try container.encode(slideId, forKey: .slideId)
        try container.encode(PIC, forKey: .PIC)
        try container.encode(DPJP, forKey: .DPJP)

        if let examinationDate = examinationDate {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateString = dateFormatter.string(from: examinationDate)
            try container.encode(dateString, forKey: .examinationDate)
        }

        if let examinationPlanDate = examinationPlanDate {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateString = dateFormatter.string(from: examinationPlanDate)
            try container.encode(dateString, forKey: .examinationPlanDate)
        }
    }
}
