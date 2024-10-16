//
//  InformationPage.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import SwiftUI

struct InformationPage: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Decimal.d24) {
                AppCard(icon: "info.circle", title: "Standar Penilaian", spacing: Decimal.d16) {
                    VStack(alignment: .leading, spacing: Decimal.d16) {
                        Text("Sistem ini menghitung bakteri sesuai rekomendasi WHO dan standar IUALTD")

                        VStack(alignment: .leading, spacing: Decimal.d16) {
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Negatif: Tidak ditemukan BTA minimal dalam 100 lapang pandang")
                            }
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Scanty: 1-9 BTA dalam 100 lapang pandang")
                            }
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Positif 1+: 10 – 99 BTA dlm 100 lapang pandang")
                            }
                            HStack(alignment: .top) {
                                Text("•")
                                Text(
                                    "Positif 2+: 1 – 10 BTA setiap 1 lapang pandang, minimal terdapat di 50 lapang pandang"
                                )
                            }
                            HStack(alignment: .top) {
                                Text("•")
                                Text(
                                    "Positif 3+: ≥ 10 BTA setiap 1 lapang pandang, minimal terdapat di 20 lapang pandang"
                                )
                            }
                        }
                        .padding(.leading, Decimal.d12)
                    }
                    .font(AppTypography.p3)
                }

                AppCard(icon: "info.circle", title: "Confidence Level", spacing: Decimal.d16) {
                    VStack(alignment: .leading, spacing: Decimal.d16) {
                        HStack(alignment: .top) {
                            Text("•")
                            Text("100% Confidence: Tidak ada keraguan dari sistem")
                        }
                        HStack(alignment: .top) {
                            Text("•")
                            Text("High Confidence: 90% - 99%")
                        }
                        HStack(alignment: .top) {
                            Text("•")
                            Text("Medium Confidence: 70%-89%")
                        }
                        HStack(alignment: .top) {
                            Text("•")
                            Text("Low Confidence: 50%-69%")
                        }
                        HStack(alignment: .top) {
                            Text("•")
                            Text("Very Low: 10% - 50%")
                        }
                        HStack(alignment: .top) {
                            Text("•")
                            Text("Unpredicted: 0% - 9%")
                        }
                    }
                    .padding(.leading, Decimal.d12)
                    .font(AppTypography.p3)
                }
            }
            .padding(.horizontal, Decimal.d20)
        }
    }
}

#Preview {
    InformationPage()
}
