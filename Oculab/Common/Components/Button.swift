//
//  Button.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 14/10/24.
//

import SwiftUI

struct CustomButton: View {
    enum ButtonSize {
        case large, small
    }

    enum ButtonColorType {
        case primary, secondary, tertiary
    }

    var title: String
    var leftIcon: String? = nil
    var rightIcon: String? = nil
    var colorType: ButtonColorType = .primary
    var size: ButtonSize = .large
    var cornerRadius: CGFloat = 8
    var isEnabled: Bool = true
    var action: () -> Void

    // Button background and foreground color based on color type and enabled state
    private var backgroundColor: Color {
        switch colorType {
        case .primary:
            return isEnabled ? AppColors.purple500 : AppColors.slate50
        case .secondary:
            return isEnabled ? AppColors.purple50 : .clear // Background clear when disabled
        case .tertiary:
            return isEnabled ? AppColors.slate0 : AppColors.slate0
        }
    }

    private var foregroundColor: Color {
        switch colorType {
        case .primary:
            return isEnabled ? AppColors.slate0 : AppColors.slate200
        case .secondary:
            return isEnabled ? AppColors.purple500 : AppColors.slate400
        case .tertiary:
            return isEnabled ? AppColors.purple500 : AppColors.slate200
        }
    }

    private var borderColor: Color {
        switch colorType {
        case .secondary:
            return isEnabled ? .clear : AppColors.slate200 // Border slate200 when disabled
        default:
            return .clear
        }
    }

    // Adjust button size based on the provided size (large or small)
    private var buttonHeight: CGFloat {
        switch size {
        case .large:
            return 50
        case .small:
            return 40
        }
    }

    private var buttonFont: Font {
        switch size {
        case .large:
            return AppTypography.s5
        case .small:
            return AppTypography.s6
        }
    }

    private var vPadding: CGFloat {
        switch size {
        case .large:
            return Decimal.d16
        case .small:
            return Decimal.d12
        }
    }

    var body: some View {
        Button(action: {
            if isEnabled {
                action()
            }
        }) {
            HStack {
                if let leftIcon = leftIcon {
                    Image(systemName: leftIcon)
                        .foregroundColor(foregroundColor)
                }

                Text(title)
                    .foregroundColor(foregroundColor)
                    .font(buttonFont)

                if let rightIcon = rightIcon {
                    Image(systemName: rightIcon)
                        .foregroundColor(foregroundColor)
                }
            }
            .padding(.vertical, vPadding)
            .frame(maxWidth: .infinity, minHeight: buttonHeight)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .opacity(isEnabled ? 1 : 0.5) // Dims the button when disabled
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 2) // Adds a border when disabled
            )
        }
        .disabled(!isEnabled) // Disables button interaction when false
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomButton(
            title: "Primary Enabled",
            leftIcon: "person.fill", // Optional left icon
            rightIcon: "chevron.right", // Optional right icon
            colorType: .primary, // Primary button type
            size: .large,
            isEnabled: true
        ) {
            print("Primary Button Tapped")
        }

        CustomButton(
            title: "Primary Disabled",
            leftIcon: "person.fill",
            rightIcon: "chevron.right",
            colorType: .primary,
            size: .large,
            isEnabled: false // Disabled
        ) {
            print("Should not be tapped")
        }

        CustomButton(
            title: "Secondary Enabled",
            colorType: .secondary,
            size: .small,
            isEnabled: true
        ) {
            print("Secondary Button Tapped")
        }

        CustomButton(
            title: "Secondary Disabled",
            colorType: .secondary,
            size: .small,
            isEnabled: false // Disabled, with clear background and slate200 border
        ) {
            print("Should not be tapped")
        }

        CustomButton(
            title: "Tertiary Enabled",
            colorType: .tertiary,
            size: .large,
            isEnabled: true
        ) {
            print("Tertiary Button Tapped")
        }

        CustomButton(
            title: "Tertiary Disabled",
            colorType: .tertiary,
            size: .large,
            isEnabled: false // Disabled
        ) {
            print("Should not be tapped")
        }
    }
}
