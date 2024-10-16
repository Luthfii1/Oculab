//
//  TBGrade.swift
//  Oculab
//
//  Created by Risa on 16/10/24.
//

enum TBGrade: String, CaseIterable {
    case negatif = "Negatif"
    case scanty = "Scanty"
    case pos1 = "Positif (1+)"
    case pos2 = "Positif (2+)"
    case pos3 = "Positif (3+)"
}

var gradeDesc: [TBGrade: String] = [
    .negatif: "Tidak ditemukan BTA dari 100 gambar lapangan pandang",
    .scanty: "Ditemukan {1-9} BTA dari 100 gambar lapangan pandang",
    .pos1: "Ditemukan {10-99} BTA dari 100 gambar lapangan pandang",
    .pos2: "Ditemukan 1-9 BTA dari {>= 50} gambar lapangan pandang",
    .pos3: "Ditemukan ≥ 10 BTA dari {>= 20} gambar lapangan pandang",
]
