//
//  UserEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 29/10/24.
//

import Foundation
import SwiftData

@Model
class User: Codable, Identifiable {
    var _id: String
    var name: String
    var role: RolesType
    var token: String?
    var email: String?
    var password: String?
    var accessPin: String?
    var previousPassword: String?
    var isFaceIdEnabled: Bool = false

    init(
        _id: String = UUID().uuidString,
        name: String = "No name",
        role: RolesType = .ADMIN,
        token: String? = nil,
        email: String? = "noName@example.com",
        password: String? = nil,
        previousPassword: String? = nil,
        accessPin: String? = "8888",
        isFaceIdEnabled: Bool = false
    ) {
        self._id = _id
        self.name = name
        self.role = role
        self.token = token
        self.email = email
        self.password = password
        self.previousPassword = previousPassword
        self.accessPin = accessPin
        self.isFaceIdEnabled = isFaceIdEnabled
    }

    enum CodingKeys: CodingKey {
        case _id
        case name
        case role
        case token
        case email
        case password
        case accessPin
        case previousPassword
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decode(String.self, forKey: ._id)
        self.name = try container.decode(String.self, forKey: .name)
        self.role = try container.decode(RolesType.self, forKey: .role)
        self.token = try container.decodeIfPresent(String.self, forKey: .token)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.password = try container.decodeIfPresent(String.self, forKey: .password)
        self.accessPin = try container.decodeIfPresent(String.self, forKey: .accessPin)
        self.previousPassword = try container.decodeIfPresent(String.self, forKey: .previousPassword)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_id, forKey: ._id)
        try container.encode(name, forKey: .name)
        try container.encode(role, forKey: .role)
        try container.encodeIfPresent(token, forKey: .token)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(password, forKey: .password)
        try container.encodeIfPresent(accessPin, forKey: .accessPin)
        try container.encodeIfPresent(previousPassword, forKey: .previousPassword)
    }
}
