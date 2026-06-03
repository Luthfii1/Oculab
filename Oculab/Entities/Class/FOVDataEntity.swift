//
//  FOVDataEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation

class FOVData: Hashable, Equatable, Codable, Identifiable {
    static func == (lhs: FOVData, rhs: FOVData) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var id: String
    var imageMLAnalyzed: String
    var imageOriginal: String
    var type: FOVType
    var order: Int
    var comment: [String]?
    var systemCount: Int
    var confidenceLevel: Double
    var verified: Bool

    init(
        id: String = AppValue.empty,
        imageMLAnalyzed: String,
        imageOriginal: String,
        type: FOVType,
        order: Int,
        comment: [String]? = nil,
        systemCount: Int,
        confidenceLevel: Double,
        verified: Bool = false
    ) {
        self.id = id
        self.imageMLAnalyzed = imageMLAnalyzed
        self.imageOriginal = imageOriginal
        self.type = type
        self.order = order
        self.comment = comment
        self.systemCount = systemCount
        self.confidenceLevel = confidenceLevel
        self.verified = verified
    }

    enum CodingKeys: String, CodingKey {
        case id
        case legacyId = "_id"
        case imageMLAnalyzed
        case imageOriginal
        case type
        case order
        case comment
        case systemCount
        case confidenceLevel
        case verified
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
        self.imageOriginal = try container.decode(String.self, forKey: .imageOriginal)
        self.imageMLAnalyzed = try container.decode(String.self, forKey: .imageMLAnalyzed)
        self.type = try container.decode(FOVType.self, forKey: .type)
        self.order = try container.decode(Int.self, forKey: .order)
        self.comment = try container.decodeIfPresent([String].self, forKey: .comment)
        self.systemCount = try container.decode(Int.self, forKey: .systemCount)
        self.confidenceLevel = try container.decode(Double.self, forKey: .confidenceLevel)
        self.verified = try container.decodeIfPresent(Bool.self, forKey: .verified) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if !id.isEmpty {
            try container.encode(id, forKey: .id)
        }
        try container.encode(imageOriginal, forKey: .imageOriginal)
        try container.encode(imageMLAnalyzed, forKey: .imageMLAnalyzed)
        try container.encode(type, forKey: .type)
        try container.encode(order, forKey: .order)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encode(systemCount, forKey: .systemCount)
        try container.encode(confidenceLevel, forKey: .confidenceLevel)
        try container.encodeIfPresent(verified, forKey: .verified)
    }
}
