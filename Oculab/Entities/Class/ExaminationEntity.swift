//
//  ExaminationEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation

class Examination: Codable, Identifiable {
    var _id: UUID
    var goal: ExamGoalType?
    var preparationType: ExamPreparationType
    var slideId: String
    var recordVideo: Data?
    var WSI: String?
    var examinationDate: Date
    var FOV: [FOVData]?
    var imagePreview: String = "https://is3.cloudhost.id/oculab-fov/oculab-fov/eead8004-2fd7-4f40-be1f-1d02cb886af4.png"
    var statusExamination: StatusType
    var systemResult: SystemExamResult?
    var expertResult: ExpertExamResult?

    init(
        _id: UUID = UUID(),
        goal: ExamGoalType?,
        preparationType: ExamPreparationType,
        slideId: String,
        recordVideo: Data?,
        WSI: String? = nil,
        examinationDate: Date,
        FOV: [FOVData]? = nil,
        imagePreview: String,
        statusExamination: StatusType,
        systemResult: SystemExamResult? = nil,
        expertResult: ExpertExamResult? = nil
    ) {
        self._id = _id
        self.goal = goal
        self.preparationType = preparationType
        self.slideId = slideId
        self.recordVideo = recordVideo
        self.WSI = WSI
        self.examinationDate = examinationDate
        self.FOV = FOV
        self.imagePreview = imagePreview
        self.statusExamination = statusExamination
        self.systemResult = systemResult
        self.expertResult = expertResult
    }

    enum CodingKeys: String, CodingKey {
        case _id
        case goal
        case preparationType
        case slideId
        case recordVideo
        case WSI
        case examinationDate
        case FOV
        case imagePreview
        case statusExamination
        case systemResult
        case expertResult
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let _idString = try container.decode(String.self, forKey: ._id)
        self._id = UUID(uuidString: _idString) ?? UUID()
        self.goal = try container.decodeIfPresent(ExamGoalType.self, forKey: .goal)
        self.preparationType = try container.decode(ExamPreparationType.self, forKey: .preparationType)
        self.slideId = try container.decode(String.self, forKey: .slideId)
        self.recordVideo = try container.decodeIfPresent(Data.self, forKey: .recordVideo)
        self.WSI = try container.decodeIfPresent(String.self, forKey: .WSI)
        self.examinationDate = try container.decode(Date.self, forKey: .examinationDate)
        self.FOV = try container.decodeIfPresent([FOVData].self, forKey: .FOV)
        self.imagePreview = try container.decode(String.self, forKey: .imagePreview)
        self.statusExamination = try container.decode(StatusType.self, forKey: .statusExamination)
        self.systemResult = try container.decodeIfPresent(SystemExamResult.self, forKey: .systemResult)
        self.expertResult = try container.decodeIfPresent(ExpertExamResult.self, forKey: .expertResult)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_id.uuidString, forKey: ._id)
        try container.encodeIfPresent(goal, forKey: .goal)
        try container.encode(preparationType, forKey: .preparationType)
        try container.encode(slideId, forKey: .slideId)
        try container.encodeIfPresent(recordVideo, forKey: .recordVideo)
        try container.encodeIfPresent(WSI, forKey: .WSI)
        try container.encode(examinationDate, forKey: .examinationDate)
        try container.encodeIfPresent(FOV, forKey: .FOV)
        try container.encode(imagePreview, forKey: .imagePreview)
        try container.encode(statusExamination, forKey: .statusExamination)
        try container.encodeIfPresent(systemResult, forKey: .systemResult)
        try container.encodeIfPresent(expertResult, forKey: .expertResult)
    }
}
