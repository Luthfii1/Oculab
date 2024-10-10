//
//  FOVDataEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation

class FOVData: Decodable, Identifiable {
    var id: UUID = .init()
    var link: String
    var type: FOVType
    var order: Int
    var comment: [String]?
    var count: Int

    init(id: UUID, link: String, type: FOVType, order: Int, comment: [String]? = nil, count: Int) {
        self.id = id
        self.link = link
        self.type = type
        self.order = order
        self.comment = comment
        self.count = count
    }
}
