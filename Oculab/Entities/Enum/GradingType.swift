//
//  GradingType.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation

enum GradingType: String, Codable, CaseIterable {
    case NEGATIVE = "Negative"
    case SCANTY = "Scanty"
    case Plus1 = "Positive 1+"
    case Plus2 = "Positive 2+"
    case Plus3 = "Positive 3+"
    case unknown = "Unknown"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = GradingType.allCases.first { $0.rawValue.caseInsensitiveCompare(rawValue) == .orderedSame } ?? .unknown
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
    
    var displayValue: String {
        switch self {
        case .NEGATIVE: return "grading_type.negative".localized
        case .SCANTY: return "grading_type.scanty".localized
        case .Plus1: return "grading_type.plus1".localized
        case .Plus2: return "grading_type.plus2".localized
        case .Plus3: return "grading_type.plus3".localized
        case .unknown: return "grading_type.unknown".localized
        }
    }

    func description(withValues value: Int) -> String {
        switch self {
        case .NEGATIVE:
            return "grading_type.description.negative".localized
        case .SCANTY:
            return "grading_type.description.scanty".localized(with: "\(value)")
        case .Plus1:
            return "grading_type.description.plus1".localized(with: "\(value)")
        case .Plus2:
            return "grading_type.description.plus2".localized(with: "\(value)")
        case .Plus3:
            return "grading_type.description.plus3".localized(with: "\(value)")
        case .unknown:
            return "grading_type.description.unknown".localized
        }
    }
}
