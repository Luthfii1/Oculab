//
//  StatusType.swift
//  Oculab
//
//  Created by Risa on 14/10/24.
//

enum StatusType: String, Codable, CaseIterable {
    case INPROGRESS
    case NEEDVALIDATION
    case NOTSTARTED
    case FINISHED
    case NONE

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let status = try container.decode(String.self)
        self = StatusType(rawValue: status.uppercased()) ?? .NONE
    }
}

extension StatusType {
    var description: String {
        switch self {
        case .INPROGRESS: return "Sedang dianalisa sistem"
        case .NEEDVALIDATION: return "Sedang Berlangsung"
        case .NOTSTARTED: return "Belum Dimulai"
        case .FINISHED: return "Selesai"
        case .NONE: return "None"
        }
    }
}
