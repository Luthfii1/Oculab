//
//  FolderCardComponent.swift
//  Oculab
//
//  Created by Risa on 14/10/24.
//

import SwiftUI

struct FolderCardComponent: View {
    var title: FOVType
    var numOfImage: Int = 0

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "rectangle.stack.fill")
                    .foregroundColor(AppColors.purple500)
                Text(title.rawValue)
                    .font(AppTypography.s4_1)
                    .padding(.leading, Decimal.d8)
                    .font(AppTypography.s4_1).foregroundStyle(AppColors.slate900)

                Spacer()
                Text("\(numOfImage) Gambar").foregroundStyle(AppColors.slate900)

                Image(systemName: "chevron.right").foregroundStyle(AppColors.slate900)
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
        title: .BTA1TO9,
        numOfImage: 9
    )
}
