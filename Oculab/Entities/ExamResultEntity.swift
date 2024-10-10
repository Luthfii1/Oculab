//
//  ExamResultEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation

class ExamResult: Decodable, Identifiable {
    var id: UUID = UUID()
    var systemGrading: GradingType
    var confidenceLevel: Int
    var finalGrading: GradingType?
    var systemBacteriaTotalCount: Int
    var bacteriaTotalCount: Int?
    var notes: String
    
    init(id: UUID, systemGrading: GradingType, confidenceLevel: Int, finalGrading: GradingType? = nil, systemBacteriaTotalCount: Int, bacteriaTotalCount: Int? = nil, notes: String) {
        self.id = id
        self.systemGrading = systemGrading
        self.confidenceLevel = confidenceLevel
        self.finalGrading = finalGrading
        self.systemBacteriaTotalCount = systemBacteriaTotalCount
        self.bacteriaTotalCount = bacteriaTotalCount
        self.notes = notes
    }
}
