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
}
