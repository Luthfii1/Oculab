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
    var id: String = AppValue.empty
    var name: String
    var role: RolesType
    /// Deprecated: tokens live in Keychain. Kept for SwiftData schema compatibility; always nil.
    var token: String?
    var healthFacilityName: String?
    var email: String?
    /// Deprecated: never persist passwords. Kept for schema compatibility; always nil.
    var password: String?
    /// Access PIN is stored in Keychain (`KeychainKey.accessPin`). This field is a non-persisted mirror for UI/decoding only — scrubbed before SwiftData save.
    var accessPin: String?
    /// Deprecated: never persist. Kept for schema compatibility; always nil.
    var previousPassword: String?
    var isFaceIdEnabled: Bool = false
    var businessModel: BusinessModelType?
    @Transient var emailVerified: Bool = false

    init(
        id: String = AppValue.empty,
        name: String = "No name",
        role: RolesType = .ADMIN,
        token: String? = nil,
        healthFacilityName: String? = nil,
        email: String? = "noName@example.com",
        password: String? = nil,
        previousPassword: String? = nil,
        accessPin: String? = nil,
        isFaceIdEnabled: Bool = false,
        businessModel: BusinessModelType? = nil,
        emailVerified: Bool = false
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.token = nil
        self.healthFacilityName = healthFacilityName
        self.email = email
        self.password = nil
        self.previousPassword = nil
        self.accessPin = accessPin
        self.isFaceIdEnabled = isFaceIdEnabled
        self.businessModel = businessModel
        self.emailVerified = emailVerified
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case legacyId = "_id"
        case name
        case role
        case healthFacilityName
        case email
        case accessPin
        case hasAccessPin
        case businessModel
        case emailVerified
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decodedId = try container.decodeIfPresent(String.self, forKey: .id) {
            self.id = decodedId
        } else if let legacyId = try container.decodeIfPresent(String.self, forKey: .legacyId) {
            self.id = legacyId
        } else {
            self.id = AppValue.empty
        }
        self.name = try container.decode(String.self, forKey: .name)
        self.role = try container.decode(RolesType.self, forKey: .role)
        self.token = nil
        self.healthFacilityName = try container.decodeIfPresent(String.self, forKey: .healthFacilityName)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.password = nil
        self.previousPassword = nil
        // Prefer Keychain PIN; API may only send hasAccessPin (no plaintext).
        if let pin = try container.decodeIfPresent(String.self, forKey: .accessPin), !pin.isEmpty {
            self.accessPin = pin
        } else if let hasPin = try container.decodeIfPresent(Bool.self, forKey: .hasAccessPin), hasPin {
            self.accessPin = KeychainHelper.string(for: .accessPin)
        } else {
            self.accessPin = KeychainHelper.string(for: .accessPin)
        }
        self.businessModel = try container.decodeIfPresent(BusinessModelType.self, forKey: .businessModel)
        self.isFaceIdEnabled = false
        self.emailVerified = try container.decodeIfPresent(Bool.self, forKey: .emailVerified) ?? false
    }

    func encode(to encoder: Encoder) throws {
        // Never encode secrets — update-user payloads must not leak password/PIN/token.
        var container = encoder.container(keyedBy: CodingKeys.self)
        if !id.isEmpty {
            try container.encode(id, forKey: .id)
        }
        try container.encode(name, forKey: .name)
        try container.encode(role, forKey: .role)
        try container.encodeIfPresent(healthFacilityName, forKey: .healthFacilityName)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(businessModel, forKey: .businessModel)
    }

    /// Persist PIN in Keychain and keep an in-memory mirror for the current session.
    func setAccessPinSecurely(_ pin: String?) {
        if let pin, !pin.isEmpty {
            KeychainHelper.set(pin, for: .accessPin)
            accessPin = pin
        } else {
            KeychainHelper.remove(.accessPin)
            accessPin = nil
        }
    }

    func loadAccessPinFromKeychain() {
        accessPin = KeychainHelper.string(for: .accessPin)
    }

    /// Strip secrets before writing to SwiftData.
    func scrubSecretsForPersistence() {
        token = nil
        password = nil
        previousPassword = nil
        // Keep Keychain as source of truth; do not leave PIN on disk.
        if let pin = accessPin, !pin.isEmpty {
            KeychainHelper.set(pin, for: .accessPin)
        }
        accessPin = nil
    }
}
