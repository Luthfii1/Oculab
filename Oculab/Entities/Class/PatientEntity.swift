//
//  PatientEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation

class Patient: Encodable, Decodable, Identifiable {
    var id: String
    var name: String
    var NIK: String
    var DoB: Date?
    var sex: SexType
    var BPJS: String?
    var medicalRecordNumber: String?
    var resultExamination: [String]?
    private var originalBirthDate: Date?
    private var originalBirthDateWireValue: String?

    init(
        id: String = AppValue.empty,
        name: String,
        NIK: String = AppValue.empty,
        DoB: Date? = nil,
        sex: SexType,
        BPJS: String? = nil,
        resultExamination: [String]? = nil,
        medicalRecordNumber: String? = nil
    ) {
        self.id = id
        self.name = name
        self.NIK = NIK
        self.DoB = DoB
        self.sex = sex
        self.BPJS = BPJS
        self.medicalRecordNumber = medicalRecordNumber
        self.resultExamination = resultExamination
    }

    enum CodingKeys: String, CodingKey {
        case id
        case legacyId = "_id"
        case name
        case NIK
        case DoB
        case sex
        case BPJS
        case medicalRecordNumber
        case resultExamination
        case patientId
    }

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let decodedId = try container.decodeIfPresent(String.self, forKey: .id) {
            self.id = decodedId
        } else if let patientId = try container.decodeIfPresent(String.self, forKey: .patientId) {
            self.id = patientId
        } else if let legacyId = try container.decodeIfPresent(String.self, forKey: .legacyId) {
            self.id = legacyId
        } else {
            self.id = AppValue.empty
        }
        self.name = try container.decode(String.self, forKey: .name)
        self.NIK = try container.decodeIfPresent(String.self, forKey: .NIK) ?? AppValue.empty
        if let rawDate = try container.decodeIfPresent(String.self, forKey: .DoB), !rawDate.isEmpty {
            guard let date = PatientBirthDateCoding.decode(rawDate) else {
                throw DecodingError.dataCorruptedError(forKey: .DoB, in: container, debugDescription: "Invalid patient birth date")
            }
            self.DoB = date
            originalBirthDate = date
            originalBirthDateWireValue = rawDate
        } else {
            self.DoB = nil
        }

        self.sex = try container.decode(SexType.self, forKey: .sex)
        self.BPJS = try container.decodeIfPresent(String.self, forKey: .BPJS)
        self.medicalRecordNumber = try container.decodeIfPresent(String.self, forKey: .medicalRecordNumber)
        self.resultExamination = try container.decodeIfPresent([String].self, forKey: .resultExamination)
    }

    /// Carry the original wire value into a detached edit snapshot. Historical
    /// timestamps must not change merely because another field was edited.
    func preserveBirthDateEncoding(from original: Patient) {
        guard DoB == original.DoB else { return }
        originalBirthDate = original.originalBirthDate
        originalBirthDateWireValue = original.originalBirthDateWireValue
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if !id.isEmpty {
            try container.encode(id, forKey: .id)
        }
        try container.encode(name, forKey: .name)
        try container.encode(NIK, forKey: .NIK)

        if let DoB {
            try container.encode(DoB == originalBirthDate ? (originalBirthDateWireValue ?? PatientBirthDateCoding.encode(DoB)) : PatientBirthDateCoding.encode(DoB), forKey: .DoB)
        }

        try container.encode(sex, forKey: .sex)
        try container.encodeIfPresent(BPJS, forKey: .BPJS)
        try container.encodeIfPresent(medicalRecordNumber, forKey: .medicalRecordNumber)
        try container.encodeIfPresent(resultExamination, forKey: .resultExamination)
    }
}
