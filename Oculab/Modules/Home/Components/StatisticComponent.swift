//
//  StatisticComponent.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/10/24.
//

import SwiftUI

struct StatisticComponent: View {
    @EnvironmentObject var presenter: SharedPresenter

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "tray.full.fill")
                    .foregroundStyle(AppColors.purple500)

                Text("Statistik Pemeriksaan")
                    .foregroundStyle(AppColors.slate900)
                    .font(AppTypography.s4_1)
                Spacer()
            }

            HStack(spacing: Decimal.d32) {
                HalfCircleProgress(progress: 0.55).offset(y: 35)

                VStack(alignment: .leading, spacing: Decimal.d4) {
                    Text("11 Tugas Selesai").font(AppTypography.h4_1)
                    Text("dari 20 Tugas").font(AppTypography.p3).foregroundStyle(AppColors.slate300)
                }
            }

//            AppButton(
//                title: "Pemeriksaan Baru",
//                leftIcon: "doc.text.magnifyingglass",
//                colorType: .primary,
//                size: .large,
//                cornerRadius: 8
//            ) {
//                presenter.newInputRecord()
//            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.slate100, lineWidth: 1)
        )
    }
}

#Preview {
    StatisticComponent().environmentObject(SharedPresenter())
}
