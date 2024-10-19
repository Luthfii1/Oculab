//
//  GradingType.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation

enum GradingType: String, Decodable, CaseIterable {
    case NEGATIVE = "Negatif"
    case SCANTY = "Scanty"
    case Plus1 = "Positif (1+)"
    case Plus2 = "Positif (2+)"
    case Plus3 = "Positif (3+)"

    var description: String {
        switch self {
        case .NEGATIVE:
            return "Tidak ditemukan BTA minimal dalam 100 lapang pandang"
        case .SCANTY:
            return "1 - 9 BTA dalam 100 lapang pandang"
        case .Plus1:
            return "10 – 99 BTA dalam 100 lapang pandang"
        case .Plus2:
            return "1 – 10 BTA setiap 1 lapang pandang, minimal terdapat di 50 lapang pandang"
        case .Plus3:
            return "≥ 10 BTA setiap 1 lapang pandang, minimal terdapat di 20 lapang pandang"
        }
    }
}

var gradingResultDesc: [GradingType: String] = [
    .NEGATIVE: "Tidak ditemukan BTA dari 100 gambar lapangan pandang",
    .SCANTY: "Ditemukan {1-9} BTA dari 100 gambar lapangan pandang",
    .Plus1: "Ditemukan {10-99} BTA dari 100 gambar lapangan pandang",
    .Plus2: "Ditemukan 1-9 BTA dari {>= 50} gambar lapangan pandang",
    .Plus3: "Ditemukan ≥ 10 BTA dari {>= 20} gambar lapangan pandang",
]
