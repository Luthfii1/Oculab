//
//  UserEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 29/10/24.
//

import Foundation

class User: Codable, Identifiable {
    var _id: String
    var name: String
    var role: RolesType
    var token: String?
    var email: String?
    var password: String?

    init(
        _id: String,
        name: String,
        role: RolesType,
        token: String? = nil,
        email: String? = nil,
        password: String? = nil
    ) {
        self._id = _id
        self.name = name
        self.role = role
        self.token = token
        self.email = email
        self.password = password
    }

    enum CodingKeys: CodingKey {
        case _id
        case name
        case role
        case token
        case email
        case password
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decode(String.self, forKey: ._id)
        self.name = try container.decode(String.self, forKey: .name)
        self.role = try container.decode(RolesType.self, forKey: .role)
        self.token = try container.decodeIfPresent(String.self, forKey: .token)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.password = try container.decodeIfPresent(String.self, forKey: .password)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_id, forKey: ._id)
        try container.encode(name, forKey: .name)
        try container.encode(role, forKey: .role)
        try container.encodeIfPresent(token, forKey: .token)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(password, forKey: .password)
    }
}
