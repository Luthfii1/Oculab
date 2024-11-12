//
//  PatientEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation

class Patient: Encodable, Decodable, Identifiable {
    var _id: String
    var name: String
    var NIK: String
    var DoB: Date?
    var sex: SexType
    var BPJS: String?
    var resultExamination: [String]?

    init(
        _id: String,
        name: String,
        NIK: String,
        DoB: Date,
        sex: SexType,
        BPJS: String? = nil,
        resultExamination: [String]? = nil
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

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self._id = try container.decode(String.self, forKey: ._id)
        self.name = try container.decode(String.self, forKey: .name)
        self.NIK = try container.decode(String.self, forKey: .NIK)

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
        self.resultExamination = try container.decodeIfPresent([String].self, forKey: .resultExamination)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(_id, forKey: ._id)
        try container.encode(name, forKey: .name)
        try container.encode(NIK, forKey: .NIK)

        if let DoB = DoB {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateString = dateFormatter.string(from: DoB)
            try container.encode(dateString, forKey: .DoB)
        }

        try container.encode(sex, forKey: .sex)
        try container.encodeIfPresent(BPJS, forKey: .BPJS)
        try container.encodeIfPresent(resultExamination, forKey: .resultExamination)
    }
}
