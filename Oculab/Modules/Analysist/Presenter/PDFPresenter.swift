//
//  PDFPresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 21/05/25.
//

import Foundation

class PDFPresenter: ObservableObject {
    @Published var data = PDFEntity(
        kopSurat: kopPDFData(),
        patient: patientPDFData(),
        preparat: preparatPDFData(),
        hasil: hasilPDFData()
    )
}
