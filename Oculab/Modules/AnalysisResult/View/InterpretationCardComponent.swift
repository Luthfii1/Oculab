//
//  InterpretationCardComponent.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 14/10/24.
//

import SwiftUI

struct InterpretationCardComponent: View {
    var type: String
    var confidenceLevel: String
    var notes: String

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(TBGrade.negatif.rawValue).font(AppTypography.h4)
                    .foregroundColor(type == TBGrade.negatif.rawValue ? AppColors.blue500 : AppColors.red500)

                HStack {
                    Image("robot")
                    Spacer().frame(width: 4)
                    Text("\(confidenceLevel) confidence level")
                        .foregroundColor(AppColors.slate300)
                }.font(AppTypography.p4)
                    .foregroundColor(AppColors.slate300)

                Spacer()

                Image(systemName: "info.circle").foregroundColor(AppColors.purple500)
            }

            Text(notes).font(AppTypography.p3)
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
        type: TBGrade.negatif.rawValue,
        confidenceLevel: "Medium",
        notes: "Tidak ditemukan BTA dari 100 gambar lapangan pandang"
        // test
    )
}
