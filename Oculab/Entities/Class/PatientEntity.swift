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
}
