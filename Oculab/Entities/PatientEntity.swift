//
//  Patient.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation

class Patient: Decodable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var NIK: String
    var age: Int
    var gender: GenderType
    var BPJS: Int?
    var resultExamination: [Examination]?
    
    init(id: UUID, name: String, NIK: String, age: Int, gender: GenderType, BPJS: Int? = nil, resultExamination: [Examination]? = nil) {
        self.id = id
        self.name = name
        self.NIK = NIK
        self.age = age
        self.gender = gender
        self.BPJS = BPJS
        self.resultExamination = resultExamination
    }
}
