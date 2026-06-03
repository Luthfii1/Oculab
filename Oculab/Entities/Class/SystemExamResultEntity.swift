//
//  SystemExamResultEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 28/10/24.
//

import Foundation

class SystemExamResult: Codable, Identifiable {
    var id: String
    var systemGrading: GradingType
    var confidenceLevelAggregated: Double
    var systemBacteriaTotalCount: Int

    init(
        id: String = AppValue.empty,
        systemGrading: GradingType,
        confidenceLevelAggregated: Double,
        systemBacteriaTotalCount: Int
    ) {
        self.id = id
        self.systemGrading = systemGrading
        self.confidenceLevelAggregated = confidenceLevelAggregated
        self.systemBacteriaTotalCount = systemBacteriaTotalCount
    }

    enum CodingKeys: String, CodingKey {
        case id
        case legacyId = "_id"
        case systemGrading
        case confidenceLevelAggregated
        case systemBacteriaTotalCount
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decodedId = try container.decodeIfPresent(String.self, forKey: .id) {
            self.id = decodedId
        } else if let legacyId = try container.decodeIfPresent(String.self, forKey: .legacyId) {
            self.id = legacyId
        } else {
            self.id = AppValue.empty
        }
        self.systemGrading = try container.decode(GradingType.self, forKey: .systemGrading)
        self.confidenceLevelAggregated = try container.decode(Double.self, forKey: .confidenceLevelAggregated)
        self.systemBacteriaTotalCount = try container.decode(Int.self, forKey: .systemBacteriaTotalCount)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if !id.isEmpty {
            try container.encode(id, forKey: .id)
        }
        try container.encode(systemGrading, forKey: .systemGrading)
        try container.encode(confidenceLevelAggregated, forKey: .confidenceLevelAggregated)
        try container.encode(systemBacteriaTotalCount, forKey: .systemBacteriaTotalCount)
    }
}
