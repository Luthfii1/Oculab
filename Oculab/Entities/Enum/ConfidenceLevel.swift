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
}
