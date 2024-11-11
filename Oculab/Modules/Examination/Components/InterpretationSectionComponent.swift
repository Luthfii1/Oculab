//
//  InterpretationSectionComponent.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/11/24.
//

import SwiftUI

struct InterpretationSectionComponent: View {
    var examination: ExaminationResultData
    var presenter: AnalysisResultPresenter
    @Binding var selectedTBGrade: String
    @Binding var numOfBTA: String
    @Binding var inspectorNotes: String
    @Binding var isVerifPopUpVisible: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Decimal.d24) {
            HStack {
                Image(systemName: "photo")
                    .foregroundColor(AppColors.purple500)
                Text("Hasil Interpretasi")
                    .font(AppTypography.s4_1)
                    .padding(.leading, Decimal.d8)
                Spacer()
                StatusTagComponent(type: .NEEDVALIDATION)
            }

            GradingCardComponent(
                type: examination.systemGrading,
                confidenceLevel: presenter.confidenceLevel,
                n: presenter.resultQuantity
            )

            AppDropdown(
                title: "Interpretasi Petugas",
                placeholder: "Pilih kategori",
                isRequired: false,
                rightIcon: "chevron.down",
                choices: GradingType.allCases.dropLast().map { ($0.rawValue, $0.rawValue) },
                selectedChoice: $selectedTBGrade
            )

            if selectedTBGrade == GradingType.SCANTY.rawValue {
                AppTextField(
                    title: "Jumlah BTA",
                    placeholder: "Contoh: 8",
                    isNumberOnly: true,
                    text: $numOfBTA
                )
            }

            AppTextBox(
                title: "Catatan Petugas",
                placeholder: "Contoh: Hanya terdapat 20 bakteri dari 60 lapangan pandang yang terkumpul",
                text: $inspectorNotes
            )

            AppButton(
                title: "Simpan Hasil Pemeriksaan",
                rightIcon: "checkmark",
                isEnabled: {
                    if selectedTBGrade == GradingType.SCANTY.rawValue {
                        return !numOfBTA.isEmpty && Int(numOfBTA) != nil
                    } else {
                        return selectedTBGrade != ""
                    }
                }()
            ) {
                isVerifPopUpVisible = true
                print("Primary Button Tapped")
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(Decimal.d12)
        .overlay(RoundedRectangle(cornerRadius: Decimal.d12).stroke(AppColors.slate100))
        .padding(.horizontal, Decimal.d20)
    }
}

// #Preview {
//    InterpretationSectionComponent()
// }
