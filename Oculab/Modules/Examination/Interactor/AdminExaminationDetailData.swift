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
    let examinations: [AdminExaminationData]
}

struct AdminExaminationData: Decodable, Identifiable {
    let _id: String
    let preparationType: String
    let slideId: String
    let statusExamination: String
    let expertResult: String?
    
    var id: String { _id }
}