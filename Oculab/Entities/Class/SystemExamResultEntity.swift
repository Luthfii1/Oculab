//
//  SystemExamResultEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 28/10/24.
//

import Foundation

class SystemExamResult: Codable, Identifiable {
    var _id: UUID
    var systemGrading: GradingType
    var confidenceLevelAggregated: Double
    var systemBacteriaTotalCount: Int

    init(
        _id: UUID = UUID(),
        systemGrading: GradingType,
        confidenceLevelAggregated: Double,
        systemBacteriaTotalCount: Int
    ) {
        self._id = _id
        self.systemGrading = systemGrading
        self.confidenceLevelAggregated = confidenceLevelAggregated
        self.systemBacteriaTotalCount = systemBacteriaTotalCount
    }

    enum CodingKeys: CodingKey {
        case _id
        case systemGrading
        case confidenceLevelAggregated
        case systemBacteriaTotalCount
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decode(UUID.self, forKey: ._id)
        self.systemGrading = try container.decode(GradingType.self, forKey: .systemGrading)
        self.confidenceLevelAggregated = try container.decode(Double.self, forKey: .confidenceLevelAggregated)
        self.systemBacteriaTotalCount = try container.decode(Int.self, forKey: .systemBacteriaTotalCount)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_id, forKey: ._id)
        try container.encode(systemGrading, forKey: .systemGrading)
        try container.encode(confidenceLevelAggregated, forKey: .confidenceLevelAggregated)
        try container.encode(systemBacteriaTotalCount, forKey: .systemBacteriaTotalCount)
    }
}
