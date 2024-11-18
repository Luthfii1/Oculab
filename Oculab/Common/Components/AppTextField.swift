//
//  AppTextField.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 14/10/24.
//

import SwiftUI

struct AppTextField: View {
    var title: String
    var isRequired: Bool = false
    var placeholder: String = ""
    var description: String? = nil
    var leftIcon: String? = nil
    var rightIcon: String? = nil
    var isError: Bool = false
    var isDisabled: Bool = false
    var isNumberOnly: Bool = false
    var length: Int = 0
    @Binding var text: String
    @State private var isPasswordVisible: Bool = false
    @FocusState private var isFocused: Bool

    private var isPasswordInput: Bool {
        rightIcon == "eye"
    }

    // Colors based on the state (error, disabled, normal)
    private var borderColor: Color {
        if isError {
            return AppColors.red500
        } else if isDisabled {
            return AppColors.slate200
        } else {
            return AppColors.slate300
        }
    }

    private var iconColor: Color {
        if isError {
            return AppColors.red500
        } else if isDisabled {
            return AppColors.slate100
        } else {
            return AppColors.purple700
        }
    }

    private var textColor: Color {
        isDisabled ? AppColors.slate400 : AppColors.slate900
    }

    private var backgroundColor: Color {
        isDisabled ? AppColors.slate50 : AppColors.slate0
    }

    var body: some View {
        VStack(alignment: .leading) {
            // Title and required indicator
            HStack {
                Text(title)
                    .font(AppTypography.s4_1)
                    .foregroundColor(textColor)
                Spacer().frame(width: 2)
                if isRequired {
                    Text("*")
                        .foregroundColor(AppColors.red500)
                }
            }

            Spacer().frame(height: 8)

            // TextField with icons inside the box
            HStack {
                if let leftIcon = leftIcon {
                    Image(systemName: leftIcon)
                        .foregroundColor(iconColor)
                        .padding(.leading, 16)
                }

                // Conditionally show TextField or SecureField
                if isPasswordInput {
                    if isPasswordVisible {
                        TextField(placeholder, text: $text)
                            .keyboardType(isNumberOnly ? .numberPad : .default)
                            .disabled(isDisabled)
                            .foregroundColor(textColor)
                            .padding(.horizontal, 16)
                            .focused($isFocused)
                            .onChange(of: text) { _, newValue in
                                handleTextChange(newValue)
                            }
                    } else {
                        SecureField(placeholder, text: $text)
                            .keyboardType(isNumberOnly ? .numberPad : .default)
                            .disabled(isDisabled)
                            .foregroundColor(textColor)
                            .padding(.horizontal, 16)
                            .focused($isFocused)
                            .onChange(of: text) { _, newValue in
                                handleTextChange(newValue)
                            }
                    }
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(isNumberOnly ? .numberPad : .default)
                        .disabled(isDisabled)
                        .foregroundColor(textColor)
                        .padding(.horizontal, 16)
                        .focused($isFocused)
                        .onChange(of: text) { _, newValue in
                            handleTextChange(newValue)
                        }
                }

                if rightIcon == "eye" {
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(iconColor)
                            .padding(.trailing, 12)
                    }
                } else if let rightIcon = rightIcon {
                    Image(systemName: rightIcon)
                        .foregroundColor(iconColor)
                        .padding(.trailing, 12)
                }
            }
            .padding(.vertical, 12)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
            .background(backgroundColor)

            Spacer().frame(height: 8)

            // Description or error message
            if let description = description, description != "" {
                Text(description)
                    .font(AppTypography.p3)
                    .foregroundColor(isError ? AppColors.red500 : AppColors.slate600)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    private func handleTextChange(_ newValue: String) {
        var updatedValue = newValue
        if isNumberOnly {
            updatedValue = newValue.filter { $0.isNumber }
        }
        if length > 0 && updatedValue.count > length {
            updatedValue = String(updatedValue.prefix(length))
        }
        if updatedValue != newValue {
            text = updatedValue
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AppTextField(
            title: "Name",
            isRequired: true,
            placeholder: "Enter your name",
            description: "This is a required field",
            leftIcon: "person.fill",
            rightIcon: "checkmark.circle",
            isError: false,
            isDisabled: false,
            text: .constant("")
        )

        AppTextField(
            title: "Email",
            isRequired: false,
            placeholder: "Enter your email",
            description: "Invalid email address",
            leftIcon: "envelope.fill",
            rightIcon: "xmark.circle",
            isError: true,
            isDisabled: false,
            text: .constant("invalid@domain")
        )

        AppTextField(
            title: "Address",
            isRequired: false,
            placeholder: "Enter your address",
            description: nil,
            leftIcon: "house.fill",
            isDisabled: true,
            text: .constant("123 Main St")
        )

        AppTextField(
            title: "Tanggal Lahir",
            isRequired: false,
            placeholder: "Pilih Tanggal",
            description: nil,
            rightIcon: "calendar",
            text: .constant("123 Main St")
        )
    }
    .padding()
}
