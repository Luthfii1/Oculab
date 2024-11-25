//
//  AppStepper.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import SwiftUI

struct AppStepper: View {
    var stepTitles: [String]
    @State var currentStep: Int = 0

    var body: some View {
//        GeometryReader { geometry in
        VStack {
            HStack(spacing: Decimal.d4) {
                ForEach(0..<stepTitles.count, id: \.self) { step in
                    HStack(spacing: Decimal.d4) {
                        if step < currentStep {
                            ZStack {
                                Circle()
                                    .fill(AppColors.purple500)
                                    .frame(width: 20, height: 20)

                                Image(systemName: "checkmark")
                                    .resizable()
                                    .frame(width: 10, height: 10)
                                    .foregroundColor(AppColors.slate0)
                            }
                        }

                        else if step == currentStep {
                            Text("\(step + 1)")
                                .font(AppTypography.s6)
                                .foregroundColor(AppColors.purple500)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(AppColors.purple500, lineWidth: 1)
                                )
                        }

                        else {
                            Text("\(step + 1)")
                                .font(AppTypography.s6)
                                .foregroundColor(AppColors.slate100)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(AppColors.slate100, lineWidth: 1)
                                )
                        }

                        Text(stepTitles[step])
                            .font(AppTypography.s4_1)
                            .foregroundColor(
                                step == currentStep ? AppColors
                                    .purple500 : (step < currentStep ? AppColors.slate900 : AppColors.slate100)
                            )

                        if step < stepTitles.count - 1 {
                            Rectangle()
                                .fill(AppColors.slate100)
//                                    .frame(width: geometry.size.width * 0.06, height: 2)
                                .frame(width: 18, height: 2)
                                .cornerRadius(Decimal.d12)
                        }
                    }
                }
            }
//            }
        }
//        .frame(maxHeight: 40)
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
