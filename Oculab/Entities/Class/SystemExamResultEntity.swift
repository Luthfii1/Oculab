//
//  SystemExamResultEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 28/10/24.
//

import Foundation

class SystemExamResult: Decodable, Identifiable {
    var _id: UUID = .init()
    var systemGrading: GradingType
    var confidenceLevelAggregated: Double
    var systemBacteriaTotalCount: Int

    init(_id: UUID, systemGrading: GradingType, confidenceLevelAggregated: Double, systemBacteriaTotalCount: Int) {
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

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decode(UUID.self, forKey: ._id)
        self.systemGrading = try container.decode(GradingType.self, forKey: .systemGrading)
        self.confidenceLevelAggregated = try container.decode(Double.self, forKey: .confidenceLevelAggregated)
        self.systemBacteriaTotalCount = try container.decode(Int.self, forKey: .systemBacteriaTotalCount)
    }
}
