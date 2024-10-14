//
//  Card 2.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 14/10/24.
//

import SwiftUI

struct Card: View {
    var icon: String
    var title: String
//    var status:
    var titleSize: Font

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppColors.purple500)
                Text(title)
                    .padding(.leading, Decimal.d8)
                Spacer()
            }
        }
        .font(AppTypography.s4_1)
        .padding(.horizontal, Decimal.d12)
        .padding(.vertical, Decimal.d16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.white)
        .cornerRadius(Decimal.d12)
        .overlay(
            RoundedRectangle(cornerRadius: Decimal.d12)
                .stroke(AppColors.slate100)
        )
        .padding(.horizontal, Decimal.d20)
    }
}

#Preview {
    Card(
        icon: "person.fill",
        title: "Data Pasien",
        titleSize: AppTypography.s5
    )
}
