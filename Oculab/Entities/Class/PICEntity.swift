//
//  PICEntity.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 01/11/24.
//

import Foundation

class PICEntity: Decodable, Identifiable {
    var _id: UUID = .init()
    var name: String
    var role: String
    var email: String

    init(
        _id: UUID,
        name: String,
        role: String,
        email: String

    ) {
        self._id = _id
        self.name = name
        self.role = role
        self.email = email
    }

    enum CodingKeys: String, CodingKey {
        case _id
        case name
        case role
        case email
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let _idString = try container.decode(String.self, forKey: ._id)
        self._id = UUID(uuidString: _idString) ?? UUID()

        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.role = try container.decodeIfPresent(String.self, forKey: .role) ?? ""
        self.email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
    }
}
