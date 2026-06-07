//
//  AnalysisProgressRing.swift
//  Oculab
//

import SwiftUI

struct AnalysisProgressRing: View {
    let progress: Int
    var lineWidth: CGFloat = 10
    var diameter: CGFloat = 112

    private var progressFraction: CGFloat {
        CGFloat(min(100, max(0, progress))) / 100.0
    }

    private var displayProgress: Int {
        min(100, max(0, progress))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.purple100, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progressFraction)
                .stroke(
                    AppColors.purple500,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: progressFraction)

            VStack(spacing: 2) {
                Text("\(displayProgress)\(AppValue.percentage)")
                    .font(AppTypography.h2)
                    .foregroundStyle(AppColors.purple600)
                Text(AppTextExamProgress.progressLabel)
                    .font(AppTypography.p4)
                    .foregroundStyle(AppColors.slate400)
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AppTextExamProgress.progressAccessibility(displayProgress))
    }
}
