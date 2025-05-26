//
//  FinishedExaminationCardData.swift
//  Oculab
//
//  Created by Bunga Prameswari on 24/05/25.
//

import Foundation

struct FinishedExaminationCardData: Decodable, Identifiable {
    var id: String {
        examinationId
    }
    var examinationId: String
    var patientId: String
    var slideId: String
    var patientName: String
    var patientDob: String
    var dpjpName: String?
    var finalGradingResult: GradingType
}


