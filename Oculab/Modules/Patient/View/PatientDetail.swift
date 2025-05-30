
//
//  PatientDetail.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 08/11/24.
//

import SwiftUI

struct PatientDetail: View {
    var body: some View {
        NavigationView {
            ScrollView {
                Spacer().frame(height: Decimal.d24)

                AppCard(icon: "person.fill", title: "Data Pasien", spacing: Decimal.d16, isEnablingEdit: true) {
                    ExtendedCard(data: [
                        ("Nama", ""),
                        ("NIK", ""),
                        ("Tanggal Lahir", ""),
                        ("Jenis Kelamin", ""),
                        ("Nomor BPJS", ""),

                    ], titleSize: AppTypography.s5)
                }

                AppCard(
                    icon: "text.badge.checkmark",
                    title: "Hasil Pemeriksaan",
                    spacing: Decimal.d16,
                    isBorderDisabled: true
                ) {
                    AppButton(title: "Pemeriksaan Baru", leftIcon: "doc.badge.plus") {}
                }
            }
            .padding(.horizontal, Decimal.d20)
            .navigationTitle("Riwayat Pemeriksaan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {}) {
                        HStack {
                            Image("back")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    PatientDetail()
}
