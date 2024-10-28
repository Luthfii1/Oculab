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
    var imagePreview: String
    var date: String
    var time: String
    var slideId: String
}
