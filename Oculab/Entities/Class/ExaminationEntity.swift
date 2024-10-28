//
//  ExaminationEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation

class Examination: Decodable, Identifiable {
    var _id: UUID = .init()
    var goal: ExamGoalType?
    var preparationType: ExamPreparationType
    var slideId: String
    var recordVideo: Data?
    var WSI: String?
    var examinationDate: Date
    var FOV: [FOVData]?
    var result: ExamResult?
    var statusExamination: StatusType
    var imagePreview: String

    init(
        _id: UUID,
        goal: ExamGoalType?,
        preparationType: ExamPreparationType?,
        slideId: String,
        recordVideo: Data?,
        WSI: String? = nil,
        timestamp: Date,
        FOV: [FOVData]? = nil,
        result: ExamResult?,
        statusExamination: StatusType,
        imagePreview: String
    ) {
        self._id = _id
        self.goal = goal
        self.preparationType = preparationType
        self.slideId = slideId
        self.recordVideo = recordVideo
        self.WSI = WSI
        self.timestamp = timestamp
        self.FOV = FOV
        self.result = result
        self.statusExamination = statusExamination
        self.imagePreview = imagePreview
    }

    enum CodingKeys: String, CodingKey {
        case _id, goal, preparationType, slideId, recordVideo, WSI, timestamp, FOV, result, statusExamination,
             imagePreview
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let _idString = try container.decode(String.self, forKey: ._id)
        self._id = UUID(uuidString: _idString) ?? UUID()

        self.goal = try container.decodeIfPresent(ExamGoalType.self, forKey: .goal)
        self.preparationType = try container.decodeIfPresent(ExamPreparationType.self, forKey: .preparationType)
        self.slideId = try container.decode(String.self, forKey: .slideId)
        self.recordVideo = try container.decodeIfPresent(Data.self, forKey: .recordVideo)
        self.WSI = try container.decodeIfPresent(String.self, forKey: .WSI)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.FOV = try container.decodeIfPresent([FOVData].self, forKey: .FOV)
        self.result = try container.decodeIfPresent(ExamResult.self, forKey: .result)
        self.statusExamination = try container.decode(StatusType.self, forKey: .statusExamination)
        self.imagePreview = try container.decode(String.self, forKey: .imagePreview)
    }
}
