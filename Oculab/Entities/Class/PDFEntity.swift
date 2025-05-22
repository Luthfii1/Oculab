//
//  PDFEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 21/05/25.
//

import Foundation

struct PDFEntity {
    var kopSurat: kopPDFData
    var patient: patientPDFData
    var preparat: preparatPDFData
    var hasil: hasilPDFData
}

struct kopPDFData {
    var desc: String = "Pathologist Expert Companion for Accessible TB Care"
    var notelp: String = "+62 838 0000 0000"
    var email: String = "ai.oculab@gmail.com"
}

struct patientPDFData {
    var name: String = "{Alya Annisa Kirana}"
    var nik: String = "{167012039484700}"
    var age: Int = 23
    var sex: String = "{Perempuan}"
    var bpjs: String = "-"
}

struct preparatPDFData {
    var id: String = "{24/11/1/0123A}"
    var place: String = "{Puskesmas Rawa Buntu}"
    var laborant: String = "{Bunga Prameswari, S.Tr.Kes}"
}

struct hasilPDFData {
    var tujuan: String = "{Skrining}"
    var jenisUji: String = "{Sewaktu}"
    var hasil: String = "{Positif (3+)}"
    var idSediaan: String = "{24/11/1/0123A}"
    var descInterpretasi: String = "{Pelaporan BTA pada Sediaan dengan Pewarnaan Z-N berdasarkan Rekomendasi IUALTD/WHO. Hasil positif pada sediaan BTA (Bakteri Tahan Asam) menjadi indikasi awal adanya infeksi mikobakteri dan potensi penyakit TB. Positifnya hasil sediaan dan tingkatan BTA mencerminkan beban bakteri relatif dan terkait dengan gejala penyakit. Terapi pasien untuk TB dapat dimulai berdasarkan hasil sediaan dan presentasi klinis, dengan perubahan status BTA yang penting untuk memantau respons terapi}"
    var descNotesPetugas: String = "{Ada kemungkinan infeksi penyakit tuberculosis}"
}
