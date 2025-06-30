//
//  ExaminationStatistic.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 06/11/24.
//

struct ExaminationStatistic: Decodable {
//    var totalFinished: Int = 0
//    var totalNotFinished: Int = 0
//    var totalPositive: Int = 0
//    var totalNegative: Int = 0
//    var totalPending: Int = 0
    var totalFinished: Int?
    var totalNotFinished: Int?
    
    var totalPositive: Int?
    var totalNegative: Int?
    var totalPending: Int?
    
    init() {
        self.totalFinished = nil
        self.totalNotFinished = nil
        self.totalPositive = nil
        self.totalNegative = nil
        self.totalPending = nil
    }
}
