//
//  AnalysisProgressRing.swift
//  Oculab
//

import SwiftUI

struct AnalysisProgressRing: View {
    let progress: Int
    let message: String

    private var progressFraction: CGFloat {
        CGFloat(min(100, max(0, progress))) / 100.0
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(AppColors.purple100, lineWidth: 12)

                Circle()
                    .trim(from: 0, to: progressFraction)
                    .stroke(
                        AppColors.purple500,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.35), value: progressFraction)

                Text("\(min(100, max(0, progress)))\(AppValue.percentage)")
                    .font(AppTypography.h2)
                    .foregroundStyle(AppColors.purple600)
            }
            .frame(width: 120, height: 120)

            Text(message)
                .font(AppTypography.p3)
                .foregroundStyle(AppColors.slate600)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }
}
