//
//  ExamPreparationType.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation

enum ExamPreparationType: String, Codable {
    case SPS
    case SP

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case "SPS", "Sewaktu":
            self = .SPS
        case "SP", "Pagi":
            self = .SP
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid value for ExamGoalType: \(rawValue)"
            )
        }
    }
}
