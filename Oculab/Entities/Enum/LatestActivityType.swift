//
//  LatestActivityType.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/10/24.
//

import Foundation

enum LatestActivityType: String, CaseIterable {
    case semua = "ALL"
    case butuhVerifikasi = "NEED_VERIFICATION"
    case belumDimulai = "NOT_STARTED"
    case belumDisimpulkan = "IN_PROGRESS"
    
    var displayValue: String {
        switch self {
        case .semua:
            return "latest_activity_type.all".localized
        case .butuhVerifikasi:
            return "latest_activity_type.need_verification".localized
        case .belumDimulai:
            return "latest_activity_type.not_started".localized
        case .belumDisimpulkan:
            return "latest_activity_type.in_progress".localized
        }
    }
}
