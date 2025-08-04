//
//  AdminExaminationCardData.swift
//  Oculab
//
//  Created by Risa on 03/08/25.
//

import Foundation

struct AdminExaminationCardData: Decodable, Identifiable {
    var id: String { observationId }
    let observationId: String
    let examinationPlanDate: String?
    let patientId: String
    let patientName: String
    let patientDob: String?
    let picName: String?
    let dpjpName: String?
}
