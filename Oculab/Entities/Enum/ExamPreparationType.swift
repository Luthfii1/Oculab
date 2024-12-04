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
    case UNKNOWN

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        self = ExamPreparationType(rawValue: rawValue.uppercased()) ?? .UNKNOWN
    }
}
