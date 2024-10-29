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
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = GradingType.allCases.first { $0.rawValue.caseInsensitiveCompare(rawValue) == .orderedSame } ?? .unknown
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    func description(withValues value: Int) -> String {
        switch self {
        case .NEGATIVE:
            return "Tidak ditemukan BTA dari 100 gambar lapangan pandang"
        case .SCANTY:
            return "Ditemukan \(value) BTA dari 100 gambar lapangan pandang"
        case .Plus1:
            return "Ditemukan \(value) BTA dari 100 gambar lapangan pandang"
        case .Plus2:
            return "Ditemukan 1-9 BTA BTA dari \(value) gambar lapangan pandang"
        case .Plus3:
            return "Ditemukan ≥ 10 BTA BTA dari \(value) gambar lapangan pandang"
        case .unknown:
            return "null"
        }
    }
}
