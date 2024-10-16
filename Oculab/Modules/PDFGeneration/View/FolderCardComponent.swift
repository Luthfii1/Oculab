//
//  FolderCardComponent.swift
//  Oculab
//
//  Created by Risa on 14/10/24.
//

import SwiftUI

struct FolderCardComponent: View {
    var title: String
    var images: String

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "rectangle.stack.fill")
                    .foregroundColor(AppColors.purple500)
                Text(title)
                    .padding(.leading, Decimal.d8)
                    .font(AppTypography.s4_1)
                Spacer()
                Text(images)
                    .font(AppTypography.p3)
                Image(systemName: "chevron.right")
            }
        }

        .padding(.horizontal, Decimal.d16)
        .padding(.vertical, Decimal.d12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.white)
        .cornerRadius(Decimal.d12)
        .overlay(
            RoundedRectangle(cornerRadius: Decimal.d8)
                .stroke(AppColors.slate100)
        )
    }
}

#Preview {
    FolderCardComponent(
        title: "0 BTA",
        images: "9 Gambar"
    )
}
