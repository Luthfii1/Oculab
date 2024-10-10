//
//  ExaminationEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation

class Examination: Decodable, Identifiable {
    var id: UUID = .init()
    var goal: ExamGoalType
    var preparationType: ExamPreparationType
    var slideID: String
    var recordVideo: Data
    var WSI: String?
    var timestamp: Date
    var FOV: [FOVData]?
    var result: ExamResult

    init(
        id: UUID,
        goal: ExamGoalType,
        preparationType: ExamPreparationType,
        slideID: String,
        recordVideo: Data,
        WSI: String? = nil,
        timestamp: Date,
        FOV: [FOVData]? = nil,
        result: ExamResult
    ) {
        self.id = id
        self.goal = goal
        self.preparationType = preparationType
        self.slideID = slideID
        self.recordVideo = recordVideo
        self.WSI = WSI
        self.timestamp = timestamp
        self.FOV = FOV
        self.result = result
    }
}
