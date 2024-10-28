//
//  ExpertExamResultEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 28/10/24.
//

import Foundation

class ExpertExamResult: Decodable, Identifiable {
    var _id: UUID = .init()
    var finalGrading: GradingType
    var bacteriaTotalCount: Int?
    var notes: String
    
    init(
        _id: UUID,
        finalGrading: GradingType,
        bacteriaTotalCount: Int? = nil,
        notes: String
    ) {
        self._id = _id
        self.finalGrading = finalGrading
        self.bacteriaTotalCount = bacteriaTotalCount
        self.notes = notes
    }
    
    enum CodingKeys: CodingKey {
        case _id
        case finalGrading
        case bacteriaTotalCount
        case notes
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decode(UUID.self, forKey: ._id)
        self.finalGrading = try container.decode(GradingType.self, forKey: .finalGrading)
        self.bacteriaTotalCount = try container.decodeIfPresent(Int.self, forKey: .bacteriaTotalCount)
        self.notes = try container.decode(String.self, forKey: .notes)
    }
}
