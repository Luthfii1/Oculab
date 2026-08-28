//
//  AdminExaminationDetailData.swift
//  Oculab
//
//  Created by Risa on 03/08/25.
//

import Foundation

struct AdminExaminationDetailData: Decodable {
    let observationId: String
    let goal: String
    let examinationPlanDate: String
    let picName: String
    let dpjpName: String
    let archivedAt: String?
    let examinations: [AdminExaminationData]

    var isArchived: Bool {
        archivedAt != nil
    }
}

struct AdminExaminationData: Decodable, Identifiable {
    let id: String
    let preparationType: String
    let slideId: String
    let statusExamination: String
    let expertResult: String?

    enum CodingKeys: String, CodingKey {
        case id
        case legacyId = "_id"
        case preparationType
        case slideId
        case statusExamination
        case expertResult
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decodedId = try container.decodeIfPresent(String.self, forKey: .id) {
            id = decodedId
        } else if let legacyId = try container.decodeIfPresent(String.self, forKey: .legacyId) {
            id = legacyId
        } else {
            id = AppValue.empty
        }
        preparationType = try container.decode(String.self, forKey: .preparationType)
        slideId = try container.decode(String.self, forKey: .slideId)
        statusExamination = try container.decode(String.self, forKey: .statusExamination)
        expertResult = try container.decodeIfPresent(String.self, forKey: .expertResult)
    }
}