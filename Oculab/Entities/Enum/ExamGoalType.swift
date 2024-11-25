//
//  ExamGoalType.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation

enum ExamGoalType: String, Codable {
    case SCREENING
    case TREATMENT

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case "SCREENING", "Skrining":
            self = .SCREENING
        case "Follow Up", "TREATMENT":
            self = .TREATMENT
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid value for ExamGoalType: \(rawValue)"
            )
        }
    }
}
