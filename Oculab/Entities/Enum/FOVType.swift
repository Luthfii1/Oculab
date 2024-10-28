//
//  FOVType.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation

enum FOVType: String, Decodable {
    case BTA0 = "0 BTA"
    case BTA1TO9 = "1-9 BTA"
    case BTAABOVE9 = "≥ 10 BTA"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        guard let type = FOVType(rawValue: rawValue) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid FOVType value: \(rawValue)"
            )
        }

        self = type
    }
}
