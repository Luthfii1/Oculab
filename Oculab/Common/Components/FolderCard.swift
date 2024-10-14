//
//  FolderCard.swift
//  Oculab
//
//  Created by Risa on 14/10/24.
//

import SwiftUI

struct FolderCard: View {
    var title: String
    var images: String

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "rectangle.stack.fill")
                    .foregroundColor(AppColors.purple500)
                Text(title)
                    .padding(.leading, Decimal.d8)
                Spacer()
                Text(images)
                Image(systemName: "chevron.right")
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
    FolderCard(
        title: "0 BTA",
        images: "9 Gambar"
    )
}
