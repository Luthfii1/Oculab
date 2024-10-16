//
//  InterpretationCardComponent.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 14/10/24.
//

import SwiftUI

struct InterpretationCardComponent: View {
    var type: TBGrade
    var confidenceLevel: ConfidenceLevel

    var body: some View {
        VStack(alignment: .leading, spacing: Decimal.d8) {
            HStack {
                Text(type.rawValue).font(AppTypography.h4)
                    .foregroundColor(type == TBGrade.negative ? AppColors.blue500 : AppColors.red500)

                HStack {
                    Image("robot")
                    Spacer().frame(width: 4)
                    Text("\(confidenceLevel.rawValue) confidence level")
                        .foregroundColor(AppColors.slate300)

                    Spacer()

                    Image(systemName: "info.circle").foregroundColor(AppColors.purple500)
                }
            }
            Text(gradeResultDesc[type]!).font(AppTypography.p3)
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
    InterpretationCardComponent(
        type: .negative,
        confidenceLevel: .mediumConfidence
    )
}
