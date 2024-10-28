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
            return "Tidak ada keraguan dari sistem"
        case .highConfidence:
            return "90% - 99%"
        case .mediumConfidence:
            return "70% - 89%"
        case .lowConfidence:
            return "50% - 69%"
        case .veryLowConfidence:
            return "10% - 50%"
        case .unpredicted:
            return "0% - 9%"
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
