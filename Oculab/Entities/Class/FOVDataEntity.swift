//
//  FOVDataEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation

class FOVData: Decodable, Identifiable {
    var _id: UUID = .init()
    var image: String
    var type: FOVType
    var order: Int
    var comment: [String]?
    var systemCount: Int
    var confidenceLevel: Double

    init(
        _id: UUID,
        image: String,
        type: FOVType,
        order: Int,
        comment: [String]? = nil,
        systemCount: Int,
        confidenceLevel: Double
    ) {
        self._id = _id
        self.image = image
        self.type = type
        self.order = order
        self.comment = comment
        self.systemCount = systemCount
        self.confidenceLevel = confidenceLevel
    }

    enum CodingKeys: CodingKey {
        case _id
        case image
        case type
        case order
        case comment
        case systemCount
        case confidenceLevel
    }

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decode(UUID.self, forKey: ._id)
        self.image = try container.decode(String.self, forKey: .image)
        self.type = try container.decode(FOVType.self, forKey: .type)
        self.order = try container.decode(Int.self, forKey: .order)
        self.comment = try container.decodeIfPresent([String].self, forKey: .comment)
        self.systemCount = try container.decode(Int.self, forKey: .systemCount)
        self.confidenceLevel = try container.decode(Double.self, forKey: .confidenceLevel)
    }
}
