//
//  KeychainHelper.swift
//  Oculab
//

import Foundation
import Security

enum KeychainKey: String {
    case accessToken
    case refreshToken
    case accessPin
}

enum KeychainHelper {
    private static let service = Bundle.main.bundleIdentifier ?? "com.Oculab.Oculab"

    @discardableResult
    static func set(_ value: String, for key: KeychainKey) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return true }

        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery.merge(attributes) { _, new in new }
            return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
        }

        return false
    }

    static func string(for key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8)
        else { return nil }
        return value
    }

    @discardableResult
    static func remove(_ key: KeychainKey) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    static func removeAll() {
        for key in [KeychainKey.accessToken, .refreshToken, .accessPin] {
            remove(key)
        }
    }

    /// Run once at app launch:
    /// 1. On a fresh install (no UserDefaults flag), wipe any Keychain items
    ///    that survived an uninstall — they'd otherwise re-authenticate the
    ///    new install as the previous user.
    /// 2. Migrate tokens previously stored in UserDefaults into Keychain.
    static func bootstrap() {
        let defaults = UserDefaults.standard
        let installedKey = "keychain.bootstrap.installed"

        if !defaults.bool(forKey: installedKey) {
            removeAll()
            defaults.set(true, forKey: installedKey)
        }

        // Legacy keys are the raw enum values used before this migration.
        let legacyAccess = "accessToken"
        let legacyRefresh = "refreshToken"

        if let access = defaults.string(forKey: legacyAccess), !access.isEmpty {
            set(access, for: .accessToken)
            defaults.removeObject(forKey: legacyAccess)
        }
        if let refresh = defaults.string(forKey: legacyRefresh), !refresh.isEmpty {
            set(refresh, for: .refreshToken)
            defaults.removeObject(forKey: legacyRefresh)
        }

        // Migrate legacy SwiftData-stored PINs if UserDefaults mirror exists.
        let legacyPin = "accessPin"
        if let pin = defaults.string(forKey: legacyPin), !pin.isEmpty {
            set(pin, for: .accessPin)
            defaults.removeObject(forKey: legacyPin)
        }
    }
}
