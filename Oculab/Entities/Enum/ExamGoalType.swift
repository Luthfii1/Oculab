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
    case UNKNOWN

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        self = ExamGoalType(rawValue: rawValue.uppercased()) ?? .UNKNOWN
    }
}
