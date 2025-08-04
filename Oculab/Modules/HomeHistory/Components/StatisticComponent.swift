//
//  StatisticComponent.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/10/24.
//

import SwiftUI

struct StatisticComponent: View {
    @EnvironmentObject var presenter: HomeHistoryPresenter
    var isLab: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: AppText.Icon.trayFullFill)
                    .foregroundStyle(AppColors.purple500)

                Text(AppTextHomeHistCompStatistic.title)
                    .foregroundStyle(AppColors.slate900)
                    .font(AppTypography.s4_1)
                Spacer()
            }

            if isLab {
                HStack(spacing: Decimal.d32) {
                    HalfCircleProgress(progress: presenter.progress)
                        .offset(y: 35)

                    VStack(alignment: .leading, spacing: Decimal.d4) {
                        Text("\(presenter.statisticExam.totalFinished ?? 0) \(AppTextHomeHistCompStatistic.tasksCompletedSuffix)").font(AppTypography.h4_1)
                        Text(
                            "\(AppTextHomeHistCompStatistic.fromTasksPrefix) \((presenter.statisticExam.totalFinished ?? 0) + (presenter.statisticExam.totalNotFinished ?? 0)) \(AppTextHomeHistCompStatistic.tasksInTotalSuffix)"

                        )
                        .font(AppTypography.p3).foregroundStyle(AppColors.slate300)
                    }
                }
            }

            else {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .center, spacing: 4) {
                        Text(String(presenter.statisticExam.totalPositive ?? 0))
                            .foregroundStyle(AppColors.red500)
                            .font(AppTypography.h1)

                        Text(AppTextHomeHistCompStatistic.positiveLabel)
                            .foregroundStyle(AppColors.slate900)
                            .font(AppTypography.s6)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(AppColors.red50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .center, spacing: 4) {
                        Text(String(presenter.statisticExam.totalNegative ?? 0))
                            .foregroundStyle(AppColors.purple500)
                            .font(AppTypography.h1)

                        Text(AppTextHomeHistCompStatistic.negativeLabel)
                            .foregroundStyle(AppColors.slate900)
                            .font(AppTypography.s6)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(AppColors.purple50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .center, spacing: 4) {
                        Text(String(presenter.statisticExam.totalPending ?? 0))
                            .foregroundStyle(AppColors.blue500)
                            .font(AppTypography.h1)

                        Text(AppTextHomeHistCompStatistic.pendingLabel)
                            .foregroundStyle(AppColors.slate900)
                            .font(AppTypography.s6)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(AppColors.blue50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
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
    StatisticComponent(isLab: false).environmentObject(HomeHistoryPresenter())
}
