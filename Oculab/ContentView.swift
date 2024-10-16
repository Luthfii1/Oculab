//
//  ContentView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 03/10/24.
//

import SwiftUI

struct ContentView: View {
    @State private var showPopup = false

    var body: some View {
        ZStack {
            ScrollView {
                Button("Show Popup") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showPopup = true
                    }
                }

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
            .background(Color.red)

            if showPopup {
                AppPopup(
                    image: "Confirm", // SF Symbol
                    title: "Simpan Hasil Pemeriksaan",
                    description: "Hasil pemeriksaan yang sudah disimpan tidak dapat diubah kembali",
                    buttons: [
                        AppButton(
                            title: "Simpan",
                            colorType: .primary,
                            size: .large,
                            isEnabled: true
                        ) {
                            print("Simpan Tapped")
                        },

                        AppButton(
                            title: "Periksa Kembali",
                            colorType: .tertiary,
                            isEnabled: true
                        ) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showPopup = false
                            }
                        }
                    ],
                    isVisible: $showPopup
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
