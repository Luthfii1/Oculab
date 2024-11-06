//
//  ExaminationEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation

class Examination: Decodable, Identifiable {
    var _id: String
    var goal: ExamGoalType?
    var preparationType: ExamPreparationType
    var slideId: String
    var recordVideo: Data?
    var WSI: String?
    var examinationDate: Date?
    var examinationPlanDate: Date?

    var FOV: [FOVData]?
    var imagePreview: String?
    var statusExamination: StatusType
    var systemResult: SystemExamResult?
    var expertResult: ExpertExamResult?

    var PIC: User?
    var DPJP: User?

    var patientId: String?
    var patientName: String?
    var patientDoB: String?

    init(
        _id: String,
        goal: ExamGoalType?,
        preparationType: ExamPreparationType,
        slideId: String,
        recordVideo: Data?,
        WSI: String? = nil,
        examinationDate: Date,
        examinationPlanDate: Date,
        FOV: [FOVData]? = nil,
        imagePreview: String? = nil,
        statusExamination: StatusType,
        systemResult: SystemExamResult? = nil,
        expertResult: ExpertExamResult? = nil,
        PIC: User? = nil,
        DPJP: User? = nil,
        patientName: String? = nil,
        patientId: String? = nil,
        patientDoB: String? = nil

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
        self.PIC = PIC
        self.DPJP = DPJP

        self.patientId = patientId
        self.patientName = patientName
        self.patientDoB = patientDoB
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
        case PIC
        case DPJP
        case examinationId
        case patientId
        case patientName
        case patientDoB
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let id = try? container.decode(String.self, forKey: ._id) {
            self._id = id
        } else if let examinationId = try? container.decode(String.self, forKey: .examinationId) {
            self._id = examinationId
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys._id,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Neither _id nor examinationId found"
                )
            )
        }

        self.goal = try container.decodeIfPresent(ExamGoalType.self, forKey: .goal)
        self.preparationType = try container.decodeIfPresent(ExamPreparationType.self, forKey: .preparationType) ?? .SP
        self.slideId = try container.decode(String.self, forKey: .slideId)
        self.recordVideo = try container.decodeIfPresent(Data.self, forKey: .recordVideo)
        self.WSI = try container.decodeIfPresent(String.self, forKey: .WSI)

        let dateString = try container.decodeIfPresent(String.self, forKey: .examinationDate) ?? ""

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if dateString != "" {
            guard let date = dateFormatter.date(from: dateString) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .examinationDate,
                    in: container,
                    debugDescription: "Date string does not match format expected by formatter."
                )
            }
            self.examinationDate = date
        }

        let datePlanString = try container.decodeIfPresent(String.self, forKey: .examinationPlanDate) ?? ""

        if datePlanString != "" {
            guard let datePlan = dateFormatter.date(from: datePlanString) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .examinationPlanDate,
                    in: container,
                    debugDescription: "Date string does not match format expected by formatter."
                )
            }
            self.examinationPlanDate = datePlan
        }

        self.FOV = try container.decodeIfPresent([FOVData].self, forKey: .FOV)
        self.imagePreview = try container.decodeIfPresent(String.self, forKey: .imagePreview)
        self.statusExamination = try container.decode(StatusType.self, forKey: .statusExamination)
        self.systemResult = try container.decodeIfPresent(SystemExamResult.self, forKey: .systemResult)
        self.expertResult = try container.decodeIfPresent(ExpertExamResult.self, forKey: .expertResult)

        self.PIC = try container.decodeIfPresent(User.self, forKey: .PIC)
        self.DPJP = try container.decodeIfPresent(User.self, forKey: .DPJP)

        self.patientId = try container.decodeIfPresent(String.self, forKey: .patientId)
        self.patientName = try container.decodeIfPresent(String.self, forKey: .patientName)

        self.patientDoB = try container.decodeIfPresent(String.self, forKey: .patientDoB)
    }
}
