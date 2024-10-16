//
//  AnalysisResultView.swift
//  Oculab
//
//  Created by Risa on 14/10/24.
//

import SwiftUI

struct AnalysisResultView: View {
    @State var selectedTBGrade: String? = nil
    @State var numOfBTA: String = ""
    @State var inspectorNotes: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Decimal.d24) {
                VStack(alignment: .leading, spacing: Decimal.d16) {
                    HStack {
                        Image(systemName: "photo")
                            .foregroundColor(AppColors.purple500)
                        Text("Hasil Gambar")
                            .font(AppTypography.s4_1)
                            .padding(.leading, Decimal.d8)
                    }
                    Text("Ketuk untuk lihat detail gambar")
                        .font(AppTypography.p3)
                        .foregroundStyle(AppColors.slate300)

                    // TODO: Hasil gambar slides

                    // TODO: Bikin IF sesuai data API nanti, numOfImage jadi len(arrayGambar)
                    FolderCardComponent(
                        title: .zeroBTA,
                        numOfImage: 9
                    )
                    FolderCardComponent(
                        title: .lowBTA,
                        numOfImage: 9
                    )
                    FolderCardComponent(
                        title: .highBTA,
                        numOfImage: 9
                    )
                }
                .padding(.horizontal, Decimal.d16)
                .padding(.vertical, Decimal.d16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(.white)
                .cornerRadius(Decimal.d12)
                .overlay(
                    RoundedRectangle(cornerRadius: Decimal.d12)
                        .stroke(AppColors.slate100)
                )
                .padding(.horizontal, Decimal.d20)

                VStack(alignment: .leading, spacing: Decimal.d24) {
                    HStack {
                        Image(systemName: "photo")
                            .foregroundColor(AppColors.purple500)
                        Text("Hasil Interpretasi")
                            .font(AppTypography.s4_1)
                            .padding(.leading, Decimal.d8)
                        Spacer()
                        StatusTagComponent(type: .draft)
                    }

                    VStack(alignment: .leading, spacing: Decimal.d16) {
                        Text("Interpretasi Sistem")
                            .font(AppTypography.s4_1)

                        HStack(alignment: .top) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppColors.orange500)
                            Text("Interpretasi sistem bukan merupakan hasil akhir untuk pasien")
                        }

                        InterpretationCardComponent(
                            type: .scanty,
                            confidenceLevel: .lowConfidence
                        )

                    }.font(AppTypography.p4)

                    VStack(alignment: .leading, spacing: Decimal.d16) {
                        AppDropdown(
                            title: "Interpretasi Petugas",
                            placeholder: "Pilih kategori",
                            isRequired: false,
                            rightIcon: "chevron.down",
                            isDisabled: false,
                            choices: TBGrade.allCases.map { $0.rawValue },
                            isExtended: true,
                            selectedChoice: $selectedTBGrade
                        )

                        if selectedTBGrade == TBGrade.scanty.rawValue {
                            AppTextField(
                                title: "Jumlah BTA",
                                isRequired: false,
                                placeholder: "Contoh: 8",
                                isError: false,
                                isDisabled: false,
                                isNumberOnly: true,
                                text: $numOfBTA
                            )
                        }

                        AppTextBox(
                            title: "Catatan Petugas",
                            placeholder: "Contoh: Hanya terdapat 20 bakteri dari 60 lapangan pandang yang terkumpul",
                            isRequired: false,
                            isDisabled: false,
                            text: $inspectorNotes
                        )

                        AppButton(
                            title: "Simpan Hasil Pemeriksaan",
                            rightIcon: "checkmark",
                            colorType: .primary,
                            size: .large,
                            isEnabled: {
                                if selectedTBGrade == TBGrade.scanty.rawValue {
                                    return !numOfBTA.isEmpty && Int(numOfBTA) != nil
                                } else {
                                    return selectedTBGrade != nil
                                }
                            }()
                        ) {
                            print("Primary Button Tapped")
                        }
                    }
                }
                .padding(.horizontal, Decimal.d16)
                .padding(.vertical, Decimal.d16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(.white)
                .cornerRadius(Decimal.d12)
                .overlay(
                    RoundedRectangle(cornerRadius: Decimal.d12)
                        .stroke(AppColors.slate100)
                )
                .padding(.horizontal, Decimal.d20)
            }
        }
    }
}

#Preview {
    AnalysisResultView()
}
