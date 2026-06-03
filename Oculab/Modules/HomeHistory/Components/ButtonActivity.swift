//
//  ButtonActivity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/10/24.
//

import SwiftUI

struct ButtonActivity: View {
    // MARK: - Properties
    let labelButton: String
    var count: Int? = nil
    let isSelected: Bool
    let action: () -> Void
    
    // MARK: - Constants
    private enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 8
        static let cornerRadius: CGFloat = 20
        static let borderWidth: CGFloat = 1
        static let borderOpacity: Double = 0.2
    }

    // MARK: - Body
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(labelButton)
                    .font(AppTypography.p4)
                    .foregroundStyle(textColor)

                if let count {
                    Text("\(count)")
                        .font(AppTypography.p5)
                        .foregroundStyle(isSelected ? AppColors.purple700 : AppColors.slate400)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(isSelected ? AppColors.purple100 : AppColors.purple50)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.verticalPadding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .overlay(borderOverlay)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Computed Properties
    private var textColor: Color {
        isSelected ? AppColors.purple600 : AppColors.slate700
    }
    
    private var backgroundColor: Color {
        isSelected ? AppColors.purple50 : Color.white
    }
    
    private var borderColor: Color {
        isSelected ? AppColors.purple500 : Color.black.opacity(Constants.borderOpacity)
    }
    
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: Constants.cornerRadius)
            .stroke(borderColor, lineWidth: Constants.borderWidth)
    }
}

#Preview {
    VStack(spacing: 16) {
        ButtonActivity(
            labelButton: "Selected Button",
            isSelected: true,
            action: { /* Preview action */ }
        )
        
        ButtonActivity(
            labelButton: "Unselected Button",
            isSelected: false,
            action: { /* Preview action */ }
        )
    }
    .padding()
}
