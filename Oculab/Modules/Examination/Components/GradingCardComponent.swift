//
//  GradingCardComponent.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 14/10/24.
//

import SwiftUI

struct GradingCardComponent: View {
    var type: GradingType = .unknown
    var confidenceLevel: ConfidenceLevel = .unpredicted
    var n: Int = 0
    var isExpert: Bool = false
    var expertNote: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Decimal.d8) {
            HStack {
                Text(type.rawValue).font(AppTypography.h4)
                    .foregroundColor(type == .NEGATIVE ? AppColors.blue500 : AppColors.red500)

                if !isExpert {
                    HStack {
                        Image(AppImage.robot)
                        Spacer().frame(width: 4)
                        Text(AppData.makeSentence([confidenceLevel.rawValue, AppMedical.Examination.confidenceLevel]))
                            .font(AppTypography.p4)
                            .foregroundColor(AppColors.slate300)

                        Spacer()
                        Button(action: {
                            Router.shared.navigateTo(.informationInterpretation)
                        }) {
                            Image(systemName: AppIcon.info)
                                .foregroundColor(AppColors.purple500)
                        }
                    }
                }
            }

            if isExpert {
                Text(expertNote ?? AppValue.empty)
                    .font(AppTypography.p3)
            } else {
                Text(type.description(withValues: n))
                    .font(AppTypography.p3)
            }
        }
        .padding(Decimal.d12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.white)
        .cornerRadius(Decimal.d8)
        .overlay(
            RoundedRectangle(cornerRadius: Decimal.d8)
                .stroke(AppColors.slate100)
        )
    }
}

#Preview {
    GradingCardComponent(
        type: .NEGATIVE,
        confidenceLevel: .mediumConfidence,
        n: 1
    )
}
