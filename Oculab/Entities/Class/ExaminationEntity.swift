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
    var examinationPlanDate: Date

    var FOV: [FOVData]?
    var imagePreview: String = "https://is3.cloudhost.id/oculab-fov/oculab-fov/eead8004-2fd7-4f40-be1f-1d02cb886af4.png"
    var statusExamination: StatusType
    var systemResult: SystemExamResult?
    var expertResult: ExpertExamResult?

    init(
        _id: UUID,
        goal: ExamGoalType?,
        preparationType: ExamPreparationType,
        slideId: String,
        recordVideo: Data?,
        WSI: String? = nil,
        examinationDate: Date,
        examinationPlanDate: Date,
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
        self.examinationPlanDate = examinationPlanDate
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
        case examinationPlanDate
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

//        self.examinationDate = try container.decode(Date.self, forKey: .examinationDate)
        // Decode the examinationDate as a string and convert it to a Date using ISO8601 format
        let dateString = try container.decode(String.self, forKey: .examinationDate)
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = dateFormatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .examinationDate,
                in: container,
                debugDescription: "Date string does not match format expected by formatter."
            )
        }
        self.examinationDate = date

        let datePlanString = try container.decode(String.self, forKey: .examinationPlanDate)

        guard let datePlan = dateFormatter.date(from: datePlanString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .examinationPlanDate,
                in: container,
                debugDescription: "Date string does not match format expected by formatter."
            )
        }
        self.examinationPlanDate = datePlan

        self.FOV = try container.decodeIfPresent([FOVData].self, forKey: .FOV)
        self.imagePreview = try container.decode(String.self, forKey: .imagePreview)
        self.statusExamination = try container.decode(StatusType.self, forKey: .statusExamination)
        self.systemResult = try container.decodeIfPresent(SystemExamResult.self, forKey: .systemResult)
        self.expertResult = try container.decodeIfPresent(ExpertExamResult.self, forKey: .expertResult)
    }
}
