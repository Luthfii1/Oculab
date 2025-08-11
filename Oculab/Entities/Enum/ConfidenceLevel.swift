//
//  ConfidenceLevel.swift
//  Oculab
//
//  Created by Risa on 16/10/24.
//

enum ConfidenceLevel: String, CaseIterable {
    case fullConfidence = "100%"
    case highConfidence = "High"
    case mediumConfidence = "Medium"
    case lowConfidence = "Low"
    case veryLowConfidence = "Very Low"
    case unpredicted = "Unpredicted"

    var confidenceRange: String {
        switch self {
        case .fullConfidence:
            return "confidence_level.full_confidence".localized
        case .highConfidence:
            return "confidence_level.high_confidence".localized
        case .mediumConfidence:
            return "confidence_level.medium_confidence".localized
        case .lowConfidence:
            return "confidence_level.low_confidence".localized
        case .veryLowConfidence:
            return "confidence_level.very_low_confidence".localized
        case .unpredicted:
            return "confidence_level.unpredicted".localized
        }
    }

    static func classify(aggregatedConfidence: Double) -> ConfidenceLevel {
        switch aggregatedConfidence {
        case 1.0:
            return .fullConfidence
        case 0.9...0.99:
            return .highConfidence
        case 0.7...0.89:
            return .mediumConfidence
        case 0.5...0.69:
            return .lowConfidence
        case 0.1...0.49:
            return .veryLowConfidence
        default:
            return .unpredicted
        }
    }
}
