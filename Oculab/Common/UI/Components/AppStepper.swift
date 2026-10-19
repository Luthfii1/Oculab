//
//  AppStepper.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import SwiftUI

struct AppStepper: View {
    var stepTitles: [String]
    var currentStep: Int = 0

    private var resolvedStep: Int { min(max(currentStep, 0), max(stepTitles.count - 1, 0)) }
    private var currentTitle: String { stepTitles.indices.contains(resolvedStep) ? stepTitles[resolvedStep] : "" }
    private var progressDescription: String {
        String(format: "common.step_progress".localized, resolvedStep + 1, stepTitles.count)
    }

    var body: some View {
        if !stepTitles.isEmpty {
            ViewThatFits(in: .horizontal) {
                horizontalSteps
                    .fixedSize(horizontal: true, vertical: false)
                VStack(alignment: .leading, spacing: 8) {
                    Text(progressDescription)
                        .font(AppTypography.p3)
                        .foregroundStyle(AppColors.slate600)
                    Text(currentTitle)
                        .font(AppTypography.s4_1)
                        .foregroundStyle(AppColors.purple700)
                        .fixedSize(horizontal: false, vertical: true)
                    ProgressView(value: Double(resolvedStep + 1), total: Double(stepTitles.count))
                        .tint(AppColors.purple500)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(currentTitle))
            .accessibilityValue(Text(progressDescription))
        }
    }

    private var horizontalSteps: some View {
        HStack(spacing: 8) {
            ForEach(stepTitles.indices, id: \.self) { step in
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(step < resolvedStep ? AppColors.purple500 : AppColors.slate0)
                        Circle()
                            .stroke(step <= resolvedStep ? AppColors.purple500 : AppColors.slate300, lineWidth: 1)
                        if step < resolvedStep {
                            Image(systemName: AppIcon.checkmark)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AppColors.slate0)
                        } else {
                            Text(String(step + 1))
                                .font(AppTypography.s6)
                                .foregroundStyle(step == resolvedStep ? AppColors.purple700 : AppColors.slate600)
                        }
                    }
                    .frame(width: 22, height: 22)
                    Text(stepTitles[step])
                        .font(AppTypography.s5)
                        .foregroundStyle(step == resolvedStep ? AppColors.purple700 : AppColors.slate600)
                    if step < stepTitles.count - 1 {
                        Rectangle().fill(AppColors.slate300).frame(width: 16, height: 1)
                    }
                }
            }
        }
    }
}

#Preview {
    VStack {
        AppStepper(
            stepTitles: ["Data Pasien", "Data Sediaan", "Hasil"],
            currentStep: 0
        )

        AppStepper(
            stepTitles: ["Data Pasien", "Data Sediaan", "Hasil"],
            currentStep: 1
        )

        AppStepper(
            stepTitles: ["Data Pasien", "Data Sediaan", "Hasil"],
            currentStep: 2
        )
    }
}
