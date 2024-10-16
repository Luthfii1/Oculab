//
//  ExamData.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import SwiftUI

struct ExamData: View {
    @State var idSediaan: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Decimal.d24) {
                AppRadioButton(title: "Tujuan Pemeriksaan", isRequired: true, choices: ["Skrinning", "Follow Up"])
                AppRadioButton(title: "Jenis Sediaan", isRequired: false, choices: ["Pagi", "Sewaktu"])
                AppTextField(title: "ID Sediaan", isRequired: true, placeholder: "Contoh: 24/11/1/0123A", text: $idSediaan)
            }
            .padding(.horizontal, Decimal.d20)
        }
    }
}

#Preview {
    ExamData()
}
