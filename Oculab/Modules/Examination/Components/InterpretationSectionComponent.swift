//
//  InterpretationSectionComponent.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/11/24.
//

import SwiftUI

enum AnalysisFocusField {
    case grading
    case countBta
    case notes
}

struct InterpretationSectionComponent: View {
    @EnvironmentObject var presenter: AnalysisResultPresenter
    var examination: ExaminationResultData
    @FocusState var focusedField: AnalysisFocusField?

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
                selectedChoice: $presenter.selectedTBGrade
            )
            .focused($focusedField, equals: .grading)

            if presenter.selectedTBGrade == GradingType.SCANTY.rawValue {
                AppTextField(
                    title: "Jumlah BTA",
                    placeholder: "Contoh: 8",
                    isNumberOnly: true,
                    text: $presenter.numOfBTA
                )
                .focused($focusedField, equals: .countBta)
            }

            AppTextBox(
                title: "Catatan Petugas",
                placeholder: "Contoh: Hanya terdapat 20 bakteri dari 60 lapangan pandang yang terkumpul",
                text: $presenter.inspectorNotes
            )
            .focused($focusedField, equals: .notes)

            AppButton(
                title: "Simpan Hasil Pemeriksaan",
                rightIcon: "checkmark",
                isEnabled: {
                    if presenter.selectedTBGrade == GradingType.SCANTY.rawValue {
                        return !presenter.numOfBTA.isEmpty && Int(presenter.numOfBTA) != nil
                    } else {
                        return presenter.selectedTBGrade != ""
                    }
                }()
            ) {
                presenter.isVerifPopUpVisible = true
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Selesai") {
                    focusedField = nil
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(Decimal.d12)
        .overlay(RoundedRectangle(cornerRadius: Decimal.d12).stroke(AppColors.slate100))
        .padding(.horizontal, Decimal.d20)
    }
}
