//
//  HealthFacilityType.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 19/08/25.
//

enum HealthFacilityType: String, CaseIterable, Identifiable {
    case INDEPENDENT_PRACTICE
    case COMMUNITY_HEALTH_CENTER
    case CLINIC
    case HOSPITAL
    case PHARMACY
    case BLOOD_TRANSFUSION_UNIT
    case HEALTH_LABORATORY
    case OPTICAL
    case MEDICAL_LAW_FACILITY
    case TRADITIONAL_HEALTH_FACILITY
    
    var id: String { rawValue }
    var localized: String {
        switch self {
        case .INDEPENDENT_PRACTICE: return "register.facility_type.independent_practice".localized
        case .COMMUNITY_HEALTH_CENTER: return "register.facility_type.community_health_center".localized
        case .CLINIC: return "register.facility_type.clinic".localized
        case .HOSPITAL: return "register.facility_type.hospital".localized
        case .PHARMACY: return "register.facility_type.pharmacy".localized
        case .BLOOD_TRANSFUSION_UNIT: return "register.facility_type.blood_transfusion_unit".localized
        case .HEALTH_LABORATORY: return "register.facility_type.health_laboratory".localized
        case .OPTICAL: return "register.facility_type.optical".localized
        case .MEDICAL_LAW_FACILITY: return "register.facility_type.medical_law_facility".localized
        case .TRADITIONAL_HEALTH_FACILITY: return "register.facility_type.traditional_health_facility".localized
        }
    }
}