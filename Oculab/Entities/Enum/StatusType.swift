//
//  StatusType.swift
//  Oculab
//
//  Created by Risa on 14/10/24.
//

enum StatusType: String, Decodable, CaseIterable {
    case INPROGRESS = "Sedang dianalisa sistem"
    case NEEDVALIDATION = "Belum disimpulkan"
    case FINISHED = "Selesai"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let status = try container.decode(String.self)
        self = StatusType.allCases.first { $0.rawValue.caseInsensitiveCompare(status) == .orderedSame } ?? .none

        // Custom mapping logic
        switch status {
        case "FINISHED":
            self = .FINISHED
        case "NEEDVALIDATION":
            self = .NEEDVALIDATION
        default:
            self = .INPROGRESS
        }
    }
}
