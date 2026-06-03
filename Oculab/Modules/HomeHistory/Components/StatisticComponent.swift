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

    private var totalTasks: Int {
        (presenter.statisticExam.totalFinished ?? 0) + (presenter.statisticExam.totalNotFinished ?? 0)
    }

    private var completedTasks: Int {
        presenter.statisticExam.totalFinished ?? 0
    }

    private var pendingTasks: Int {
        max(totalTasks - completedTasks, 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: AppIcon.trayFullFill)
                    .font(.body)
                    .foregroundStyle(AppColors.purple500)

                Text(AppTextHomeHistCompStatistic.title)
                    .font(AppTypography.s4_1)
                    .foregroundStyle(AppColors.slate900)

                Spacer(minLength: 0)
            }

            if isLab {
                labStatisticsBody
            } else {
                adminStatisticsBody
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.slate0)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.slate100, lineWidth: 1)
        )
    }

    private var labStatisticsBody: some View {
        HStack(alignment: .center, spacing: 0) {
            HalfCircleProgress(progress: presenter.progress)
                .frame(width: 112, height: 58)

            VStack(alignment: .leading, spacing: 10) {
                Text(
                    String(
                        format: AppTextHomeHistCompStatistic.completionSummary,
                        completedTasks,
                        totalTasks
                    )
                )
                .font(AppTypography.h4_1)
                .foregroundStyle(AppColors.slate900)
                .fixedSize(horizontal: false, vertical: true)

                if totalTasks > 0 {
                    HStack(spacing: 8) {
                        breakdownChip(
                            value: completedTasks,
                            label: AppTextHomeHistCompStatistic.completedChipLabel,
                            tint: AppColors.purple500,
                            background: AppColors.purple50
                        )
                        breakdownChip(
                            value: pendingTasks,
                            label: AppTextHomeHistCompStatistic.pendingChipLabel,
                            tint: AppColors.slate500,
                            background: AppColors.slate100
                        )
                    }
                }

                Text(AppTextHomeHistCompStatistic.completionHint)
                    .font(AppTypography.p3)
                    .foregroundStyle(AppColors.slate400)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(AppColors.purple50.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func breakdownChip(
        value: Int,
        label: String,
        tint: Color,
        background: Color
    ) -> some View {
        HStack(spacing: 4) {
            Text(String(value))
                .font(AppTypography.s6)
                .foregroundStyle(tint)
            Text(label)
                .font(AppTypography.p5)
                .foregroundStyle(AppColors.slate500)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(background)
        .clipShape(Capsule())
    }

    private var adminStatisticsBody: some View {
        HStack(alignment: .center, spacing: 10) {
            statisticTile(
                value: presenter.statisticExam.totalPositive ?? 0,
                label: AppTextHomeHistCompStatistic.positiveLabel,
                valueColor: AppColors.red500,
                background: AppColors.red50
            )
            statisticTile(
                value: presenter.statisticExam.totalNegative ?? 0,
                label: AppTextHomeHistCompStatistic.negativeLabel,
                valueColor: AppColors.purple500,
                background: AppColors.purple50
            )
            statisticTile(
                value: presenter.statisticExam.totalPending ?? 0,
                label: AppState.pending,
                valueColor: AppColors.blue500,
                background: AppColors.blue50
            )
        }
    }

    private func statisticTile(
        value: Int,
        label: String,
        valueColor: Color,
        background: Color
    ) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text(String(value))
                .font(AppTypography.h1)
                .foregroundStyle(valueColor)

            Text(label)
                .font(AppTypography.s6)
                .foregroundStyle(AppColors.slate900)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    StatisticComponent(isLab: true)
        .environmentObject(HomeHistoryPresenter())
        .padding()
}
