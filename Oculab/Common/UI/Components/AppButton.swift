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

    var id = UUID()
    var title: String
    var leftIcon: String? = nil
    var rightIcon: String? = nil
    var colorType: ButtonColorType = .primary
    var size: ButtonSize = .large
    var cornerRadius: CGFloat = 8
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var titleColor: Color? = nil
    var action: () -> Void

    // Button background and foreground color based on color type, enabled state, and pressed state
    private var backgroundColor: Color {
        switch colorType {
        case .primary:
            return isEnabled ? AppColors.purple500 : AppColors.slate50
        case .secondary:
            return isEnabled ? AppColors.purple50 : .clear
        case .tertiary:
            return .clear
        case let .destructive(type):
            return type == .primary
                ? (isEnabled ? AppColors.red500 : AppColors.slate50)
                : (isEnabled ? AppColors.red50 : AppColors.slate50)
        case let .neutral(type):
            return type == .primary ? (isEnabled ? AppColors.slate0 : AppColors.slate50) : .clear
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
            return 44
        default:
            switch size {
            case .large:
                return 50
            case .small:
                return 44
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
            return 8
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
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                        .accessibilityHidden(true)
                } else if let leftIcon {
                    Image(systemName: leftIcon)
                        .accessibilityHidden(true)
                }

                Text(title)
                    .font(buttonFont)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if let rightIcon, !isLoading {
                    Image(systemName: rightIcon)
                        .accessibilityHidden(true)
                }
            }
            .foregroundColor(titleColor ?? foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, vPadding)
            .frame(maxWidth: frameWidth, minHeight: buttonHeight)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .buttonStyle(AppPressButtonStyle())
        .disabled(!isEnabled || isLoading)
    }
}

private struct AppPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

#Preview {
    VStack(spacing: 20) {
        AppButton(
            title: "PREVIEW Primary Enabled PREVIEW",
            leftIcon: AppIcon.personFill, // Optional left icon
            rightIcon: AppIcon.forward, // Optional right icon
            colorType: .primary, // Primary button type
            size: .large,
            isEnabled: true
        ) {
            print("LOG Primary Button Tapped LOG")
        }

        AppButton(
            title: "PREVIEW Primary Disabled PREVIEW",
            leftIcon: AppIcon.personFill,
            rightIcon: AppIcon.forward,
            colorType: .primary,
            size: .large,
            isEnabled: false // Disabled
        ) {
            print("LOG Should not be tapped LOG")
        }

        AppButton(
            title: "PREVIEW Secondary Enabled PREVIEW",
            colorType: .secondary,
            size: .small,
            isEnabled: true
        ) {
            print("LOG Secondary Button Tapped LOG")
        }

        AppButton(
            title: "PREVIEW Secondary Disabled PREVIEW",
            colorType: .secondary,
            size: .small,
            isEnabled: false // Disabled, with clear background and slate200 border
        ) {
            print("LOG Should not be tapped LOG")
        }

        AppButton(
            title: "PREVIEW Tertiary Enabled PREVIEW",
            colorType: .tertiary,
            size: .large,
            isEnabled: true
        ) {
            print("LOG Tertiary Button Tapped LOG")
        }

        AppButton(
            title: "PREVIEW Tertiary Disabled PREVIEW",
            colorType: .tertiary,
            size: .large,
            isEnabled: false // Disabled
        ) {
            print("LOG Should not be tapped LOG")
        }

        AppButton(
            title: "PREVIEW Destructive Primary Enabled PREVIEW",
            colorType: .destructive(.primary),
            size: .small,
            isEnabled: true
        ) {
            print("LOG Destructive Button Tapped LOG")
        }

        AppButton(
            title: "PREVIEW Destructive Secondary Enabled PREVIEW",
            colorType: .destructive(.secondary),
            size: .small,
            isEnabled: true
        ) {
            print("LOG Destructive Button Tapped LOG")
        }

        AppButton(
            title: "PREVIEW Neutral Primary Enabled PREVIEW",
            colorType: .neutral(.primary),
            size: .small,
            isEnabled: true
        ) {
            print("LOG Neutral Button Tapped LOG")
        }

        AppButton(
            title: "PREVIEW Neutral Secondary Enabled PREVIEW",
            colorType: .neutral(.secondary),
            size: .small,
            isEnabled: true
        ) {
            print("LOG Neutral Button Tapped LOG")
        }

        HStack {
            AppButton(
                title: "PREVIEW Primary Enabled PREVIEW",
                leftIcon: AppIcon.personFill, // Optional left icon
                rightIcon: AppIcon.forward, // Optional right icon
                colorType: .primary, // Primary button type
                size: .large,
                isEnabled: true
            ) {
                print("LOG Primary Button Tapped LOG")
            }

            AppButton(
                title: "PREVIEW Primary Enabled PREVIEW",
                leftIcon: AppIcon.personFill, // Optional left icon
                rightIcon: AppIcon.forward, // Optional right icon
                colorType: .primary, // Primary button type
                size: .large,
                isEnabled: true
            ) {
                print("LOG Primary Button Tapped LOG")
            }
        }
    }
}
