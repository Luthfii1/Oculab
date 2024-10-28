//
//  StatisticComponent.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/10/24.
//

import SwiftUI

struct StatisticComponent: View {
    @EnvironmentObject var homePresenter: HomePresenter

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "tray.full.fill")
                    .foregroundStyle(AppColors.purple500)

                Text("Statistik Pemeriksaan")
                    .foregroundStyle(AppColors.slate900)
                    .font(AppTypography.s4_1)
            }

            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .center, spacing: 4) {
                    Text(String(homePresenter.statisticExam.numberOfPositive))
                        .foregroundStyle(AppColors.red500)
                        .font(AppTypography.h1)

                    Text("Positif")
                        .foregroundStyle(AppColors.slate900)
                        .font(AppTypography.s6)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(AppColors.red50)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .center, spacing: 4) {
                    Text(String(homePresenter.statisticExam.numberOfNegative))
                        .foregroundStyle(AppColors.purple500)
                        .font(AppTypography.h1)

                    Text("Negatif")
                        .foregroundStyle(AppColors.slate900)
                        .font(AppTypography.s6)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(AppColors.purple50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            AppButton(
                title: "Pemeriksaan Baru",
                leftIcon: "doc.text.magnifyingglass",
                colorType: .primary,
                size: .large,
                cornerRadius: 8
            ) {
                homePresenter.newInputRecord()
            }
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
    StatisticComponent()
}
