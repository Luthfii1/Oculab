//
//  StatusType.swift
//  Oculab
//
//  Created by Risa on 14/10/24.
//

enum StatusType: String, Codable, CaseIterable {
    case INPROGRESS = "Sedang dianalisa sistem"
    case NEEDVALIDATION = "Sedang Berlangsung"
    case NOTSTARTED = "Belum Dimulai"
    case FINISHED = "Selesai"
    case NONE = ""

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let status = try container.decode(String.self)
        self = StatusType.allCases.first { $0.rawValue.caseInsensitiveCompare(status) == .orderedSame } ?? .NONE

        // Custom mapping logic
        switch status {
        case "FINISHED":
            self = .FINISHED
        case "NEEDVALIDATION":
            self = .NEEDVALIDATION
        case "NOTSTARTED":
            self = .NOTSTARTED
        case "INPROGRESS":
            self = .INPROGRESS
        default:
            self = .NONE
        }
    }
}
