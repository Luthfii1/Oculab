//
//  PatientEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation

class Patient: Decodable, Identifiable {
    var _id: UUID = .init()
    var name: String
    var NIK: String
    var DoB: Date
    var sex: SexType
    var BPJS: Int?
    var resultExamination: [Examination]?

    init(
        _id: UUID,
        name: String,
        NIK: String,
        DoB: Date,
        sex: SexType,
        BPJS: Int? = nil,
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
    }

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decode(UUID.self, forKey: ._id)
        self.name = try container.decode(String.self, forKey: .name)
        self.NIK = try container.decode(String.self, forKey: .NIK)
        self.DoB = try container.decode(Date.self, forKey: .DoB)
        self.sex = try container.decode(SexType.self, forKey: .sex)
        self.BPJS = try container.decodeIfPresent(Int.self, forKey: .BPJS)
        self.resultExamination = try container.decodeIfPresent([Examination].self, forKey: .resultExamination)
    }
}
