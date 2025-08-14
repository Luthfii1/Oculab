//
//  CryptoUtils.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 28/10/24.
//

import CryptoKit
import Foundation

enum CryptoUtils {
    private static let key = SymmetricKey(size: .bits256)

    // MARK: Encrypt and Decrypt String using AES-GCM

    static func encrypt(_ plaintext: String) throws -> Data {
        guard let data = plaintext.data(using: .utf8) else {
            throw EncryptionError.invalidInput
        }

        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }

    static func decrypt(_ encryptedData: Data) throws -> String {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)

        // Decrypt the data
        let decryptedData = try AES.GCM.open(sealedBox, using: key)

        // Convert decrypted data to a String
        guard let decryptedText = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.invalidOutput
        }

        return decryptedText
    }

    // MARK: Encrypt and Decrypt integer using AES-GCM

    static func encrypt(_ value: Int) throws -> Data {
        let data = withUnsafeBytes(of: value) { Data($0) }
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }

    static func decryptToInt(_ encryptedData: Data) throws -> Int {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)

        // Convert decrypted data back to Int
        guard decryptedData.count == MemoryLayout<Int>.size else {
            throw EncryptionError.invalidOutput
        }

        return decryptedData.withUnsafeBytes { $0.load(as: Int.self) }
    }

    // MARK: Encrypt and Decrypt double using AES-GCM

    static func encrypt(_ value: Double) throws -> Data {
        let data = withUnsafeBytes(of: value) { Data($0) }
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }

    static func decryptToDouble(_ encryptedData: Data) throws -> Double {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)

        // Convert decrypted data back to Double
        guard decryptedData.count == MemoryLayout<Double>.size else {
            throw EncryptionError.invalidOutput
        }

        return decryptedData.withUnsafeBytes { $0.load(as: Double.self) }
    }

    // MARK: Encrypt and Decrypt Date using AES-GCM

    static func encrypt(_ date: Date) throws -> Data {
        let timeInterval = date.timeIntervalSince1970
        return try encrypt(timeInterval)
    }

    static func decryptToDate(_ encryptedData: Data) throws -> Date {
        let timeInterval = try decryptToDouble(encryptedData)
        return Date(timeIntervalSince1970: timeInterval)
    }
}

// Custom error types for handling encryption errors
enum EncryptionError: Error {
    case invalidInput
    case invalidOutput
}
