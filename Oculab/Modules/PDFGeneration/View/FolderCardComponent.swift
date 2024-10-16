//
//  FolderCardComponent.swift
//  Oculab
//
//  Created by Risa on 14/10/24.
//

import SwiftUI

struct FolderCardComponent: View {
    enum BTAfolder: String, CaseIterable {
        case zero = "0 BTA"
        case low = "1-9 BTA"
        case high = "≥ 10 BTA"
    }

    var title: BTAfolder
    var numOfImage: Int = 0

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "rectangle.stack.fill")
                    .foregroundColor(AppColors.purple500)
                Text(title.rawValue)
                    .font(AppTypography.s4_1)
                    .padding(.leading, Decimal.d8)
                    .font(AppTypography.s4_1)
                Spacer()
                Text("\(numOfImage) Gambar")
                Image(systemName: "chevron.right")
            }
        }
        .font(AppTypography.p3)
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
        title: .zero,
        numOfImage: 9
    )
}
