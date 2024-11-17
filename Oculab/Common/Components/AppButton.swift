//
//  AppButton.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 14/10/24.
//

import SwiftUI

struct AppButton: View, Identifiable {
    enum ButtonSize {
        case large, small
    }

    enum ButtonColorType: Equatable {
        case primary, secondary, tertiary
        case destructive(DestructiveType)
        case neutral(NeutralType)

        enum DestructiveType {
            case primary, secondary
        }

        enum NeutralType {
            case primary, secondary
        }
    }

    @State private var isPressed: Bool = false

    var id = UUID()
    var title: String
    var leftIcon: String? = nil
    var rightIcon: String? = nil
    var colorType: ButtonColorType = .primary
    var size: ButtonSize = .large
    var cornerRadius: CGFloat = 8
    var isEnabled: Bool = true
    var titleColor: Color? = nil
    var action: () -> Void

    // Button background and foreground color based on color type, enabled state, and pressed state
    private var backgroundColor: Color {
        if isPressed {
            switch colorType {
            case .primary:
                return AppColors.purple700
            case .secondary:
                return AppColors.purple100
            case .tertiary:
                return AppColors.slate0
            case let .destructive(type):
                switch type {
                case .primary:
                    return AppColors.red700
                case .secondary:
                    return AppColors.red100
                }
            case let .neutral(type):
                switch type {
                case .primary:
                    return AppColors.slate50
                case .secondary:
                    return .clear
                }
            }
        } else {
            switch colorType {
            case .primary:
                return isEnabled ? AppColors.purple500 : AppColors.slate50
            case .secondary:
                return isEnabled ? AppColors.purple50 : .clear
            case .tertiary:
                return .clear
            case let .destructive(type):
                switch type {
                case .primary:
                    return isEnabled ? AppColors.red500 : AppColors.slate50
                case .secondary:
                    return isEnabled ? AppColors.red50 : AppColors.slate50
                }
            case let .neutral(type):
                switch type {
                case .primary:
                    return isEnabled ? AppColors.slate0 : AppColors.slate50
                case .secondary:
                    return .clear
                }
            }
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
        case let .destructive(type):
            switch type {
            case .primary:
                return isEnabled ? AppColors.slate0 : AppColors.slate200
            case .secondary:
                return isEnabled ? AppColors.red500 : AppColors.slate200
            }
        case let .neutral(type):
            switch type {
            case .primary:
                return isEnabled ? AppColors.slate900 : AppColors.slate200
            case .secondary:
                return isEnabled ? AppColors.slate0 : AppColors.slate200
            }
        }
    }

    private var borderColor: Color {
        switch colorType {
        case .secondary:
            return isEnabled ? .clear : AppColors.slate200
        default:
            return .clear
        }
    }

    // Adjust button size based on the provided size (large or small)
    private var buttonHeight: CGFloat {
        switch colorType {
        case .tertiary:
            return 0 // No padding for tertiary buttons
        default:
            switch size {
            case .large:
                return 50
            case .small:
                return 40
            }
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

    // Only apply vertical padding for non-tertiary buttons
    private var vPadding: CGFloat {
        switch colorType {
        case .tertiary:
            return 0 // No padding for tertiary buttons
        default:
            switch size {
            case .large:
                return Decimal.d16
            case .small:
                return Decimal.d12
            }
        }
    }

    // Tertiary button doesnt have infinite width frame
    private var frameWidth: CGFloat? {
        colorType == .tertiary ? nil : .infinity
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
                    .foregroundColor(titleColor ?? foregroundColor)
                    .font(buttonFont)

                if leftIcon != nil && rightIcon != nil {
                    Spacer()
                }

                if let rightIcon = rightIcon {
                    Image(systemName: rightIcon)
                        .foregroundColor(foregroundColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, vPadding) // Use dynamic vertical padding
            .frame(maxWidth: frameWidth, minHeight: buttonHeight)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .opacity(isEnabled ? 1 : 0.5) // Dims the button when disabled
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1) // Adds a border when disabled
            )
            .onTapGesture {
                if isEnabled {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPressed = false
                        }
                        action()
                    }
                }
            }
        }
        .disabled(!isEnabled) // Disables button interaction when false
    }
}

#Preview {
    VStack(spacing: 20) {
        AppButton(
            title: "Primary Enabled",
            leftIcon: "person.fill", // Optional left icon
            rightIcon: "chevron.right", // Optional right icon
            colorType: .primary, // Primary button type
            size: .large,
            isEnabled: true
        ) {
            print("Primary Button Tapped")
        }

        AppButton(
            title: "Primary Disabled",
            leftIcon: "person.fill",
            rightIcon: "chevron.right",
            colorType: .primary,
            size: .large,
            isEnabled: false // Disabled
        ) {
            print("Should not be tapped")
        }

        AppButton(
            title: "Secondary Enabled",
            colorType: .secondary,
            size: .small,
            isEnabled: true
        ) {
            print("Secondary Button Tapped")
        }

        AppButton(
            title: "Secondary Disabled",
            colorType: .secondary,
            size: .small,
            isEnabled: false // Disabled, with clear background and slate200 border
        ) {
            print("Should not be tapped")
        }

        AppButton(
            title: "Tertiary Enabled",
            colorType: .tertiary,
            size: .large,
            isEnabled: true
        ) {
            print("Tertiary Button Tapped")
        }

        AppButton(
            title: "Tertiary Disabled",
            colorType: .tertiary,
            size: .large,
            isEnabled: false // Disabled
        ) {
            print("Should not be tapped")
        }

        AppButton(
            title: "Destructive Primary Enabled",
            colorType: .destructive(.primary),
            size: .small,
            isEnabled: true
        ) {
            print("Destructive Button Tapped")
        }

        AppButton(
            title: "Destructive Secondary Enabled",
            colorType: .destructive(.secondary),
            size: .small,
            isEnabled: true
        ) {
            print("Destructive Button Tapped")
        }

        AppButton(
            title: "Neutral Primary Enabled",
            colorType: .neutral(.primary),
            size: .small,
            isEnabled: true
        ) {
            print("Neutral Button Tapped")
        }

        AppButton(
            title: "Neutral Secondary Enabled",
            colorType: .neutral(.secondary),
            size: .small,
            isEnabled: true
        ) {
            print("Neutral Button Tapped")
        }

        HStack {
            AppButton(
                title: "Primary Enabled",
                leftIcon: "person.fill", // Optional left icon
                rightIcon: "chevron.right", // Optional right icon
                colorType: .primary, // Primary button type
                size: .large,
                isEnabled: true
            ) {
                print("Primary Button Tapped")
            }

            AppButton(
                title: "Primary Enabled",
                leftIcon: "person.fill", // Optional left icon
                rightIcon: "chevron.right", // Optional right icon
                colorType: .primary, // Primary button type
                size: .large,
                isEnabled: true
            ) {
                print("Primary Button Tapped")
            }
        }
    }
}
