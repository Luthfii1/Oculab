//
//  ExpertExamResultEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 28/10/24.
//

import Foundation

class ExpertExamResult: Codable, Identifiable {
    var id: String
    var finalGrading: GradingType
    var bacteriaTotalCount: Int?
    var notes: String?

    init(
        id: String = AppValue.empty,
        finalGrading: GradingType,
        bacteriaTotalCount: Int? = nil,
        notes: String
    ) {
        self.id = id
        self.finalGrading = finalGrading
        self.bacteriaTotalCount = bacteriaTotalCount
        self.notes = notes
    }

    enum CodingKeys: String, CodingKey {
        case id
        case legacyId = "_id"
        case finalGrading
        case bacteriaTotalCount
        case notes
    }

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decodedId = try container.decodeIfPresent(String.self, forKey: .id) {
            self.id = decodedId
        } else if let legacyId = try container.decodeIfPresent(String.self, forKey: .legacyId) {
            self.id = legacyId
        } else {
            self.id = AppValue.empty
        }
        self.finalGrading = try container.decode(GradingType.self, forKey: .finalGrading)
        self.bacteriaTotalCount = try container.decodeIfPresent(Int.self, forKey: .bacteriaTotalCount)
        self.notes = try container.decode(String.self, forKey: .notes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if !id.isEmpty {
            try container.encode(id, forKey: .id)
        }
        try container.encode(finalGrading, forKey: .finalGrading)
        try container.encodeIfPresent(bacteriaTotalCount, forKey: .bacteriaTotalCount)
        try container.encode(notes, forKey: .notes)
    }
}
