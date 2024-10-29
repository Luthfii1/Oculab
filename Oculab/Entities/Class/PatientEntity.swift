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
    var DoB: Date
    var sex: SexType
    var BPJS: Int?
    var resultExamination: [Examination]?

    init(
        _id: UUID = UUID(),
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

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        do {
            // Decode each property individually with error logging
            let idString = try container.decode(String.self, forKey: ._id)
            guard let uuid = UUID(uuidString: idString) else {
                throw DecodingError.dataCorruptedError(
                    forKey: ._id,
                    in: container,
                    debugDescription: "Invalid UUID format: \(idString)"
                )
            }
            self._id = uuid
        } catch {
            print("Decoding error for _id: \(error)")
            throw error
        }

        do {
            self.name = try container.decode(String.self, forKey: .name)
        } catch {
            print("Decoding error for name: \(error)")
            throw error
        }

        do {
            self.NIK = try container.decode(String.self, forKey: .NIK)
        } catch {
            print("Decoding error for NIK: \(error)")
            throw error
        }

        do {
            let dateString = try container.decode(String.self, forKey: .DoB)
            let dateFormatter = ISO8601DateFormatter()

            // Configure the dateFormatter to handle Zulu time (UTC)
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            guard let date = dateFormatter.date(from: dateString) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .DoB,
                    in: container,
                    debugDescription: "Invalid date format: \(dateString)"
                )
            }
            self.DoB = date
        } catch {
            print("Decoding error for DoB: \(error)")
            throw error
        }

        do {
            let sexString = try container.decode(String.self, forKey: .sex)
            guard let sex = SexType(rawValue: sexString.uppercased()) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .sex,
                    in: container,
                    debugDescription: "Invalid value for sex: \(sexString)"
                )
            }
            self.sex = sex
        } catch {
            print("Decoding error for sex: \(error)")
            throw error
        }

        do {
            self.BPJS = try container.decodeIfPresent(Int.self, forKey: .BPJS)
        } catch {
            print("Decoding error for BPJS: \(error)")
            throw error
        }

        do {
            self.resultExamination = try container
                .decodeIfPresent([Examination].self, forKey: .resultExamination) ?? []
        } catch {
            print("Decoding error for resultExamination: \(error)")
            throw error
        }
    }
}
