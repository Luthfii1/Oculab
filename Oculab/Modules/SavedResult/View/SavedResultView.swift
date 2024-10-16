//
//  SavedResultView.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import SwiftUI

struct SavedResultView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Decimal.d24) {
                ExtendableCard(
                    icon: "person.fill",
                    title: "Data Pasien",
                    data: [
                        (key: "Nama Pasien", value: "Alya Annisa Kirana"),
                        (key: "NIK Pasien", value: "167012039484700"),
                        (key: "Umur Pasien", value: "23 Tahun"),
                        (key: "Jenis Kelamin", value: "Perempuan"),
                        (key: "Nomor BPJS", value: "06L30077675"),
                    ],
                    titleSize: AppTypography.s5
                )

                ExtendableCard(
                    icon: "doc.text.magnifyingglass",
                    title: "Detail Pemeriksaan",
                    data: [
                        (key: "Alasan Pemeriksaan", value: "Follow Up"),
                        (key: "Jenis Sediaan", value: "Sewaktu"),
                        (key: "ID Sediaan", value: "24/11/1/0123A"),

                    ],
                    titleSize: AppTypography.s6
                )

                AppCard(icon: "photo", title: "Hasil Gambar", spacing: Decimal.d16) {
                    VStack(alignment: .leading, spacing: Decimal.d16) {
                        Text("Ketuk untuk lihat detail gambar")
                            .font(AppTypography.p3)
                            .foregroundStyle(AppColors.slate300)

                        RoundedRectangle(cornerRadius: Decimal.d8)
                            .foregroundStyle(AppColors.slate50)
                            .frame(height: 200)

                        FolderCardComponent(
                            title: .zero,
                            numOfImage: 9
                        )
                        FolderCardComponent(
                            title: .low,
                            numOfImage: 9
                        )
                        FolderCardComponent(
                            title: .high,
                            numOfImage: 9
                        )
                    }
                }

                AppCard(icon: "text.badge.checkmark", title: "Hasil Interpretasi", spacing: Decimal.d24) {
                    VStack(alignment: .leading, spacing: Decimal.d8) {
                        Text("Interpretasi Petugas")
                            .font(AppTypography.s5)
                            .foregroundColor(AppColors.slate300)
                        InterpretationCardComponent(
                            type: .scanty,
                            confidenceLevel: .lowConfidence
                        )
                    }

                    VStack(alignment: .leading, spacing: Decimal.d8) {
                        Text("Interpretasi Sistem")
                            .font(AppTypography.s5)
                            .foregroundColor(AppColors.slate300)
                        HStack(alignment: .top) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppColors.orange500)

                            Text("Interpretasi sistem bukan merupakan hasil akhir untuk pasien")
                                .font(AppTypography.p4)
                        }
                        InterpretationCardComponent(
                            type: .scanty,
                            confidenceLevel: .lowConfidence
                        )
                    }

                    VStack(alignment: .leading, spacing: Decimal.d16) {
                        AppButton(
                            title: "Lihat PDF",
                            rightIcon: "doc.text",
                            colorType: .secondary,
                            size: .small,
                            isEnabled: true
                        ) {
                            print("Lihat PDF Tapped")
                        }

                        AppButton(
                            title: "Laporkan ke SITB",
                            rightIcon: "paperplane",
                            size: .small,
                            isEnabled: true
                        ) {
                            print("Lihat PDF Tapped")
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Decimal.d16)
    }
}

#Preview {
    SavedResultView()
}
