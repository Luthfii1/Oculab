//
//  ExpertExamResultEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 28/10/24.
//

import Foundation

class ExpertExamResult: Codable, Identifiable {
    var _id: String
    var finalGrading: GradingType
    var bacteriaTotalCount: Int?
    var notes: String

    init(
        _id: String,
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
        self._id = try container.decode(String.self, forKey: ._id)
        self.finalGrading = try container.decode(GradingType.self, forKey: .finalGrading)
        self.bacteriaTotalCount = try container.decodeIfPresent(Int.self, forKey: .bacteriaTotalCount)
        self.notes = try container.decode(String.self, forKey: .notes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_id, forKey: ._id) // Store UUID as String for encoding
        try container.encode(finalGrading, forKey: .finalGrading)
        try container.encodeIfPresent(bacteriaTotalCount, forKey: .bacteriaTotalCount)
        try container.encode(notes, forKey: .notes)
    }
}
