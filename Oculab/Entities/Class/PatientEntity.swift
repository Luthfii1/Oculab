//
//  PatientEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation

class Patient: Codable, Identifiable {
    var _id: UUID
    var name: String
    var NIK: String
    var DoB: Date?
    var sex: SexType
    var BPJS: String?
    var resultExamination: [Examination]?

    init(
        _id: UUID = UUID(),
        name: String,
        NIK: String,
        DoB: Date,
        sex: SexType,
        BPJS: String? = nil,
        resultExamination: [Examination]? = nil
    ) {
        self._id = _id
        self.name = name
        self.NIK = NIK
        self.DoB = DoB
        self.sex = sex
        self.BPJS = BPJS
        self.resultExamination = resultExamination
    }

    enum CodingKeys: CodingKey {
        case _id
        case name
        case NIK
        case DoB
        case sex
        case BPJS
        case resultExamination
        case patientId
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let _idString = try container.decodeIfPresent(String.self, forKey: ._id) ?? container.decodeIfPresent(
            String.self,
            forKey: .patientId
        ) {
            self._id = UUID(uuidString: _idString) ?? UUID()
        } else {
            self._id = UUID()
        }

        self.name = try container.decode(String.self, forKey: .name)
        self.NIK = try container.decode(String.self, forKey: .NIK)
//        self.DoB = try container.decode(Date.self, forKey: .DoB)
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let dateString = try container.decodeIfPresent(String.self, forKey: .DoB) ?? ""

        if dateString != "" {
            guard let date = dateFormatter.date(from: dateString) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .DoB,
                    in: container,
                    debugDescription: "Date string does not match format expected by formatter."
                )
            }
            self.DoB = date
        }

        self.sex = try container.decode(SexType.self, forKey: .sex)
        self.BPJS = try container.decodeIfPresent(String.self, forKey: .BPJS)
        self.resultExamination = try container.decodeIfPresent([Examination].self, forKey: .resultExamination)
    }
}
