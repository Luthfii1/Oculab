//
//  TBGrade.swift
//  Oculab
//
//  Created by Risa on 16/10/24.
//

enum TBGrade: String, CaseIterable {
    case negative = "Negatif"
    case scanty = "Scanty"
    case positive1 = "Positif (1+)"
    case positive2 = "Positif (2+)"
    case positive3 = "Positif (3+)"

    var description: String {
        switch self {
        case .negative:
            return "Tidak ditemukan BTA minimal dalam 100 lapang pandang"
        case .scanty:
            return "1 - 9 BTA dalam 100 lapang pandang"
        case .positive1:
            return "10 – 99 BTA dalam 100 lapang pandang"
        case .positive2:
            return "1 – 10 BTA setiap 1 lapang pandang, minimal terdapat di 50 lapang pandang"
        case .positive3:
            return "≥ 10 BTA setiap 1 lapang pandang, minimal terdapat di 20 lapang pandang"
        }
    }
}

var gradeResultDesc: [TBGrade: String] = [
    .negative: "Tidak ditemukan BTA dari 100 gambar lapangan pandang",
    .scanty: "Ditemukan {1-9} BTA dari 100 gambar lapangan pandang",
    .positive1: "Ditemukan {10-99} BTA dari 100 gambar lapangan pandang",
    .positive2: "Ditemukan 1-9 BTA dari {>= 50} gambar lapangan pandang",
    .positive3: "Ditemukan ≥ 10 BTA dari {>= 20} gambar lapangan pandang",
]
