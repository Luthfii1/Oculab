//
//  StatusType.swift
//  Oculab
//
//  Created by Risa on 14/10/24.
//

enum StatusType: String, Decodable, CaseIterable {
    case draft = "Belum disimpulkan"
    case done = "Selesai"
    case none = ""

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let status = try container.decode(String.self)
        self = StatusType.allCases.first { $0.rawValue.caseInsensitiveCompare(status) == .orderedSame } ?? .none

        // Custom mapping logic
        switch status {
        case "completed":
            self = .done
        case "pending":
            self = .draft
        default:
            self = .none
        }
    }
}
