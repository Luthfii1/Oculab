//
//  LaborantInfoComponent.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 06/11/24.
//

import SwiftUI

struct LaborantInfoComponent: View {
    var pic: String
    var dpjp: String

    var body: some View {
        VStack(alignment: .leading, spacing: Decimal.d16) {
            VStack(alignment: .leading, spacing: Decimal.d8) {
                Text("Petugas Pemeriksaan")
                    .font(AppTypography.h5)
                Text(pic)
                    .font(AppTypography.p3)
            }

            VStack(alignment: .leading, spacing: Decimal.d8) {
                Text("Ditugaskan Oleh")
                    .font(AppTypography.h5)
                Text(dpjp)
                    .font(AppTypography.p3)
            }
        }.padding(Decimal.d12)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .cornerRadius(Decimal.d12)
            .overlay(
                RoundedRectangle(cornerRadius: Decimal.d12)
                    .stroke(AppColors.slate100)
            )
    }
}
