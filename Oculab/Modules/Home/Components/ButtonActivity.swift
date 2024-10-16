//
//  ButtonActivity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/10/24.
//

import SwiftUI

struct ButtonActivity: View {
    var labelButton: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(labelButton)
                .font(AppTypography.p4)
                .foregroundStyle(
                    isSelected ? AppColors.purple600 : AppColors
                        .slate900
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.purple50 : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? AppColors.purple500 : Color.black.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

#Preview {
    ButtonActivity(labelButton: "Semua", isSelected: true, action: { print("Hai") })
}
