//
//  AnalysisResultView.swift
//  Oculab
//
//  Created by Risa on 14/10/24.
//

import SwiftUI

struct AnalysisResultView: View {
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

                    VStack(alignment: .leading, spacing: Decimal.d16) {
                        Text("Ketuk untuk lihat detail gambar")
                            .font(AppTypography.p3)
                            .foregroundStyle(AppColors.slate300)

                        RoundedRectangle(cornerRadius: Decimal.d8)
                            .foregroundStyle(AppColors.slate50)
                            .frame(height: 200)

                        FolderCard(
                            title: "0 BTA",
                            images: "9 Gambar"
                        )
                        FolderCard(
                            title: "1-9 BTA",
                            images: "9 Gambar"
                        )
                        FolderCard(
                            title: "≥ 10 BTA",
                            images: "9 Gambar"
                        )
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

                VStack(alignment: .leading, spacing: Decimal.d16) {
                    HStack {
                        Image(systemName: "photo")
                            .foregroundColor(AppColors.purple500)
                        Text("Hasil Interpretasi")
                            .padding(.leading, Decimal.d8)
                            .font(AppTypography.s4_1)
                        Spacer()
                        StatusTag(type: .done)
                    }

                    VStack(alignment: .leading, spacing: Decimal.d16) {
                        Text("Interpretasi Sistem")
                            .font(AppTypography.s4_1)

                        HStack(alignment: .top) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(AppColors.blue400)
                            Text("Sistem ini menghitung bakteri sesuai standar IUALTD")
                        }

                        HStack(alignment: .top) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppColors.orange500)
                            Text("Interpretasi sistem bukan merupakan hasil akhir untuk pasien")
                        }
                        InterpretationCard(
                            type: "Normal",
                            confidenceLevel: "Medium",
                            notes: "Tidak ditemukan BTA dari 100 gambar lapangan pandang"
                        )

                    }.font(AppTypography.p4)

                    AppTextField(
                        title: "Jumlah BTA",
                        isRequired: true,
                        placeholder: "Contoh: 8",
                        isError: false,
                        isDisabled: false,
                        text: .constant("")
                    )

                    AppTextBox(
                        title: "Catatan Petugas",
                        placeholder: "Contoh: Hanya terdapat 20 bakteri dari 60 lapangan pandang yang terkumpul",
                        isRequired: false,
                        isDisabled: false,
                        text: .constant("")
                    )

                    AppButton(
                        title: "Simpan Hasil Pemeriksaan",
                        rightIcon: "checkmark", // Optional right icon
                        colorType: .primary, // Primary button type
                        size: .large,
                        isEnabled: true
                    ) {
                        print("Primary Button Tapped")
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
