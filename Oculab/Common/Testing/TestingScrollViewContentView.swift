//
//  TestingScrollViewContentView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/10/24.
//

import SwiftUI

struct TestingScrollViewContentView: View {
    var body: some View {
        ScrollView {
            AppTextBox(
                title: "Description",
                placeholder: "Enter your description here...",
                isRequired: true,
                description: "This is a required field",
                isDisabled: false,
                text: .constant("")
            )
            ExtendableCard(
                icon: "person.fill",
                title: "Data Pasien",
                isExtendable: true,
                data: [
                    (key: "Nama Pasien", value: "Alya Annisa Kirana"),
                    (key: "NIK Pasien", value: "167012039484700"),
                    (key: "Umur Pasien", value: "23 Tahun"),
                    (key: "Jenis Kelamin", value: "Perempuan"),
                    (key: "Nomor BPJS", value: "06L30077675")
                ],
                titleSize: AppTypography.s5
            )
            ExtendableCard(
                icon: "person.fill",
                title: "Data Pasien",
                isExtendable: true,
                data: [
                    (key: "Nama Pasien", value: "Alya Annisa Kirana"),
                    (key: "NIK Pasien", value: "167012039484700"),
                    (key: "Umur Pasien", value: "23 Tahun"),
                    (key: "Jenis Kelamin", value: "Perempuan"),
                    (key: "Nomor BPJS", value: "06L30077675")
                ],
                titleSize: AppTypography.s5
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .background(.red)
    }
}

#Preview {
    TestingScrollViewContentView()
}
