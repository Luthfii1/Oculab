//
//  UnfinishedExaminationCard.swift
//  Oculab
//
//  Created by Bunga Prameswari on 30/06/25.
//

import Foundation

struct UnfinishedExaminationCardData: Decodable, Identifiable {
    let id: String
    let slideId: String
    let examinationPlanDate: String?
    let statusExamination: StatusType
    let patientId: String
    let patientName: String
    let patientDob: String?
    let picName: String?
    let dpjpName: String?
}
