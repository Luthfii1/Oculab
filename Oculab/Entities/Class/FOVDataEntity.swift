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

    init(_id: UUID, image: String, type: FOVType, order: Int, comment: [String]? = nil, systemCount: Int, confidenceLevel: Double) {
        self._id = _id
        self.image = image
        self.type = type
        self.order = order
        self.comment = comment
        self.systemCount = systemCount
        self.confidenceLevel = confidenceLevel
    }
}
