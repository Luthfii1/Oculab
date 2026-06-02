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
    var healthFacilityName: String?
    var email: String?
    var password: String?
    var accessPin: String?
    var previousPassword: String?
    var isFaceIdEnabled: Bool = false
    var businessModel: BusinessModelType?

    init(
        _id: String = UUID().uuidString,
        name: String = "No name",
        role: RolesType = .ADMIN,
        token: String? = nil,
        healthFacilityName: String? = nil,
        email: String? = "noName@example.com",
        password: String? = nil,
        previousPassword: String? = nil,
        accessPin: String? = nil,
        isFaceIdEnabled: Bool = false,
        businessModel: BusinessModelType? = nil
    ) {
        self._id = _id
        self.name = name
        self.role = role
        self.token = token
        self.healthFacilityName = healthFacilityName
        self.email = email
        self.password = password
        self.previousPassword = previousPassword
        self.accessPin = accessPin
        self.isFaceIdEnabled = isFaceIdEnabled
        self.businessModel = businessModel
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case legacyId = "_id"
        case name
        case role
        case token
        case healthFacilityName
        case email
        case password
        case accessPin
        case previousPassword
        case businessModel
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let id = try container.decodeIfPresent(String.self, forKey: .id) {
            self._id = id
        } else {
            self._id = try container.decode(String.self, forKey: .legacyId)
        }
        self.name = try container.decode(String.self, forKey: .name)
        self.role = try container.decode(RolesType.self, forKey: .role)
        self.token = try container.decodeIfPresent(String.self, forKey: .token)
        self.healthFacilityName = try container.decodeIfPresent(String.self, forKey: .healthFacilityName)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.password = try container.decodeIfPresent(String.self, forKey: .password)
        self.accessPin = try container.decodeIfPresent(String.self, forKey: .accessPin)
        self.previousPassword = try container.decodeIfPresent(String.self, forKey: .previousPassword)
        self.businessModel = try container.decodeIfPresent(BusinessModelType.self, forKey: .businessModel)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(role, forKey: .role)
        try container.encodeIfPresent(token, forKey: .token)
        try container.encodeIfPresent(healthFacilityName, forKey: .healthFacilityName)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(password, forKey: .password)
        try container.encodeIfPresent(accessPin, forKey: .accessPin)
        try container.encodeIfPresent(previousPassword, forKey: .previousPassword)
        try container.encodeIfPresent(businessModel, forKey: .businessModel)
    }
}
