//
//  StatusType.swift
//  Oculab
//
//  Created by Risa on 14/10/24.
//

import Foundation

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
        case .INPROGRESS: return "status_type.in_progress".localized
        case .NEEDVALIDATION: return "status_type.need_validation".localized
        case .NOTSTARTED: return "status_type.not_started".localized
        case .FINISHED: return "status_type.finished".localized
        case .NONE: return "status_type.none".localized
        }
    }
}
