//
//  InstructionPage.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import SwiftUI

struct InstructionPage: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Decimal.d24) {
                AppCard(icon: "list.number", title: "Persiapan Pemeriksaan", spacing: Decimal.d16) {
                    VStack(alignment: .leading, spacing: Decimal.d16) {
                        HStack(alignment: .top) {
                            Text("•")
                            Text("Gunakan lensa objektif 10x untuk menentukan fokus, kemudian teteskan minyak imersi")
                        }
                        HStack(alignment: .top) {
                            Text("•")
                            Text("Pastikan lensa objektif telah diatur ke perbesaran 100x setelah fokus ditemukan")
                        }
                        HStack(alignment: .top) {
                            Text("•")
                            Text("Pasang perangkat Anda dengan lensa kamera menempel pada lensa okuler")
                        }
                        HStack(alignment: .top) {
                            Text("•")
                            Text(
                                "Pastikan Anda berada di lokasi dengan jaringan yang lancar"
                            )
                        }
                    }
                    .padding(.leading, Decimal.d12)
                    .font(AppTypography.p3)
                }

                AppCard(icon: "camera.fill", title: "Instruksi Pengambilan Gambar", spacing: Decimal.d16) {
                    VStack(spacing: Decimal.d16) {
                        HStack(alignment: .top) {
                            Text("•")
                            Text("Pastikan sediaan tetap terlihat di layar dan selalu dalam fokus optimal")
                        }
                        HStack(alignment: .top) {
                            Text("•")
                            Text(
                                "Baca sediaan mulai dari ujung kiri ke ujung kanan mengikuti skema pemindaian untuk pemeriksaan apusan"
                            )
                        }
                        Image("Instruction")

                        HStack(alignment: .top) {
                            Text("•")
                            Text(
                                "Progress pengambilan gambar keseluruhan akan terlihat di kanan atas"
                            )
                        }
                    }
                    .padding(.leading, Decimal.d12)
                    .font(AppTypography.p3)
                }

                AppButton(
                    title: "Mulai Pengambilan Gambar",
                    leftIcon: "camera", // Optional left icon
                    colorType: .primary, // Primary button type
                    size: .large,
                    isEnabled: true
                ) {
                    print("Primary Button Tapped")
                }
            }
            .padding(.horizontal, Decimal.d20)
        }
    }
}

#Preview {
    InstructionPage()
}
