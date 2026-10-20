//
//  ExaminationResult.swift
//  Oculab
//
//  Created by Risa on 31/05/25.
//

import Foundation

struct ExaminationResultCardData: Codable, Identifiable {
    let id: String
    let slideId: String
    let statusExamination: StatusType
    let patientName: String
    let patientDob: Date
    let examinationDate: Date
    let dpjpName: String?
    let finalGradingResult: String?
    
    enum CodingKeys: String, CodingKey {
        case id, slideId, statusExamination, patientName, patientDob, examinationDate, dpjpName, finalGradingResult
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        slideId = try container.decode(String.self, forKey: .slideId)
        statusExamination = try container.decode(StatusType.self, forKey: .statusExamination)
        patientName = try container.decode(String.self, forKey: .patientName)
        dpjpName = try container.decodeIfPresent(String.self, forKey: .dpjpName)
        finalGradingResult = try container.decodeIfPresent(String.self, forKey: .finalGradingResult)
        
        let dobString = try container.decode(String.self, forKey: .patientDob)
        guard let birthDate = PatientBirthDateCoding.decode(dobString) else {
            throw DecodingError.dataCorruptedError(forKey: .patientDob, in: container, debugDescription: "Invalid patient birth date")
        }
        patientDob = birthDate
        let examDateString = try container.decode(String.self, forKey: .examinationDate)
        guard let examDate = PatientBirthDateCoding.decodeInstant(examDateString) else {
            throw DecodingError.dataCorruptedError(forKey: .examinationDate, in: container, debugDescription: "Invalid examination timestamp")
        }
        examinationDate = examDate
    }
}
