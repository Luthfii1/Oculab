//
//  FOVType.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation

enum FOVType: String, Hashable, Codable {
    case BTA0 = "0 BTA"
    case BTA1TO9 = "1-9 BTA"
    case BTAABOVE9 = "≥ 10 BTA"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        if let type = FOVType(rawValue: rawValue) {
            self = type
            return
        }

        switch rawValue {
        case "BTA_0":
            self = .BTA0
        case "BTA_1_TO_9":
            self = .BTA1TO9
        case "BTA_ABOVE_9":
            self = .BTAABOVE9
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid FOVType value: \(rawValue)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
