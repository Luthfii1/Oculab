//
//  FinishedExaminationCardData.swift
//  Oculab
//
//  Created by Bunga Prameswari on 24/05/25.
//
//import Foundation
//
//struct FinishedExaminationCardData: Codable, Identifiable {
//    var id: String
//    var patientId: String
//    var slideId: String
//    var patientName: String
//    var patientDob: String
//    var dpjpName: String
//    var finalGradingResult: String
//    
//    enum CodingKeys: String, CodingKey {
//        case id = "examinationId"
//        case patientId
//        case slideId
//        case patientName
//        case patientDob
//        case dpjpName
//        case finalGradingResult
//    }
//}

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
    var dpjpName: String
    var finalGradingResult: String?
}
