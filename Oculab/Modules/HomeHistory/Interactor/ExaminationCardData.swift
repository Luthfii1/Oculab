//
//  ExaminationCardData.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 22/10/24.
//

import Foundation

struct ExaminationCardData: Decodable, Identifiable {
    var id: String {
        examinationId
    }

    var examinationId: String
    var statusExamination: StatusType
    var datePlan: String
    var date: String
    var slideId: String
    var patientName: String
    var patientDob: String
    var patientId: String
    var picName: String
    var picId: String
}
