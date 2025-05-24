//
//  PDFEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 21/05/25.
//

import Foundation

struct PDFEntity: Decodable, Equatable {
    var kopPDFData: kopPDFData
    var patientPDFData: patientPDFData
    var preparatPDFData: preparatPDFData
    var hasilPDFData: hasilPDFData
}

struct kopPDFData: Decodable, Equatable {
    var desc: String
    var notelp: String
    var email: String
}

struct patientPDFData: Decodable, Equatable {
    var name: String
    var nik: String
    var age: Int
    var sex: String
    var bpjs: String
}

struct preparatPDFData: Decodable, Equatable {
    var id: String
    var place: String
    var laborant: String
    var dpjp: String
}

struct hasilPDFData: Decodable, Equatable {
    var tujuan: String
    var jenisUji: String
    var hasil: String
    var idSediaan: String
    var descInterpretasi: String
    var descNotesPetugas: String
}
