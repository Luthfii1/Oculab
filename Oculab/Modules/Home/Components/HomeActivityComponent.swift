//
//  HomeActivityComponent.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import SwiftUI

struct HomeActivityComponent: View {
    var fileName: String
    var slideId: String
    var status: StatusType
    var date: String
    var time: String

    var body: some View {
        VStack(alignment: .leading, spacing: Decimal.d12) {
            ZStack(alignment: .topTrailing) {
                Image(fileName)
                    .resizable()
                    .frame(height: 114)

                StatusTagComponent(type: status)
                    .padding(Decimal.d6) // Padding for the status tag
            }
            .cornerRadius(Decimal.d8)

            VStack(alignment: .leading, spacing: Decimal.d8) {
                HStack {
                    Text(date)
                    Spacer()
                    Text(time)
                }
                .font(AppTypography.p5)
                .foregroundColor(AppColors.slate300)

                Text(slideId).font(AppTypography.h4_1)
            }
        }
        .padding(.horizontal, Decimal.d12)
        .padding(.vertical, Decimal.d12)
//            .frame(maxWidth: geometry.size.width, minHeight: 190, alignment: .topLeading)
        .cornerRadius(Decimal.d12)
        .overlay(
            RoundedRectangle(cornerRadius: Decimal.d12)
                .stroke(AppColors.slate100)
        )
    }
}

// }

#Preview {
    HomeActivityComponent(
        fileName: "Instruction",
        slideId: "24/11/1/0123A",
        status: .draft,
        date: "18 September 2024",
        time: "14.39"
    )
}
