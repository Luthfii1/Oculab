//
//  GradingType.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation

enum GradingType: String, Codable, CaseIterable {
    case NEGATIVE = "NEGATIVE"
    case SCANTY = "SCANTY"
    case Plus1 = "POSITIVE 1+"
    case Plus2 = "POSITIVE 2+"
    case Plus3 = "POSITIVE 3+"
    case unknown = "Unknown"

    /// Canonical value expected by the backend API (`PLUS_1`, not `POSITIVE 1+`).
    var apiValue: String {
        switch self {
        case .Plus1: return "PLUS_1"
        case .Plus2: return "PLUS_2"
        case .Plus3: return "PLUS_3"
        default: return rawValue
        }
    }

    static func fromAPIValue(_ value: String) -> GradingType {
        switch value.uppercased() {
        case "NEGATIVE": return .NEGATIVE
        case "SCANTY": return .SCANTY
        case "PLUS_1", "POSITIVE 1+": return .Plus1
        case "PLUS_2", "POSITIVE 2+": return .Plus2
        case "PLUS_3", "POSITIVE 3+": return .Plus3
        default:
            return GradingType.allCases.first {
                $0.rawValue.caseInsensitiveCompare(value) == .orderedSame
            } ?? .unknown
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = GradingType.fromAPIValue(rawValue)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(apiValue)
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
