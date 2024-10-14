//
//  Status.swift
//  Oculab
//
//  Created by Risa on 14/10/24.
//

import SwiftUI

struct Status: View {
    var title: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .foregroundStyle(AppColors.orange500)
        }
        .font(AppTypography.s6)
        .padding(.horizontal, Decimal.d8)
        .padding(.vertical, Decimal.d6)
        .background(AppColors.orange50)
        .cornerRadius(Decimal.d4)
    }
}

#Preview {
    Status(
        title: "Belum disimpulkan"
    )
}
