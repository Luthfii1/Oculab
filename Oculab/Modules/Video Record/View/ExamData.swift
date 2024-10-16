//
//  ExamData.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import SwiftUI

struct ExamData: View {
    @State var idSediaan: String = ""
    @State var fileName: String = "Instruction"

    var body: some View {
        VStack(spacing: Decimal.d24) {
            AppStepper(
                stepTitles: ["Data Pasien", "Data Sediaan", "Hasil"],
                currentStep: 1
            )

            ScrollView {
                VStack(alignment: .leading, spacing: Decimal.d24) {
                    AppRadioButton(title: "Tujuan Pemeriksaan", isRequired: true, choices: ["Skrinning", "Follow Up"])
                    AppRadioButton(title: "Jenis Sediaan", isRequired: true, choices: ["Pagi", "Sewaktu"])
                    AppTextField(
                        title: "ID Sediaan",
                        isRequired: true,
                        placeholder: "Contoh: 24/11/1/0123A",
                        text: $idSediaan
                    )
                    AppFileInput(
                        title: "Gambar Sediaan",
                        isRequired: true,
                        isEmpty: false,
                        selectedFileName: fileName
                    )

                    // Button section with fixed width for 'Kembali'
                    HStack {
                        // "Kembali" button takes 1/3 of the width
                        AppButton(
                            title: "Kembali",
                            leftIcon: "arrow.left",
                            colorType: .tertiary,
                            isEnabled: true
                        ) {
                            print("Kembali Tapped")
                        }
                        .frame(maxWidth: .infinity) // Use flexible width
                        .frame(width: UIScreen.main.bounds.width / 3.5) // 1/3 of the screen width

                        Spacer() // Add spacer to push the "Mulai Analisis" button to the right

                        // "Mulai Analisis" button takes remaining space
                        AppButton(
                            title: "Mulai Analisis",
                            rightIcon: "arrow.right",
                            size: .small,
                            isEnabled: true
                        ) {
                            print("Mulai Analisis Tapped")
                        }
                        .frame(maxWidth: .infinity) // Use remaining space
                    }
                }
            }
        }.padding(.horizontal, Decimal.d20)
    }
}

#Preview {
    ExamData()
}
