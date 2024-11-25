//
//  AppTextBox.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 14/10/24.
//

import SwiftUI

struct AppTextBox: View {
    var title: String
    var placeholder: String = ""
    var isRequired: Bool = false
    var description: String? = nil
    var isDisabled: Bool = false
    @Binding var text: String

    @State private var internalText: String = ""

    // Colors based on the state (disabled or normal)
    private var textColor: Color {
        AppColors.slate900
    }

    private var backgroundColor: Color {
        isDisabled ? AppColors.slate50 : AppColors.slate0
    }

    private var borderColor: Color {
        isDisabled ? AppColors.slate100 : AppColors.slate200
    }

    var body: some View {
        VStack(alignment: .leading) {
            // Title and required indicator
            HStack {
                Text(title)
                    .font(AppTypography.s4_1)
                    .foregroundColor(textColor)
                if isRequired {
                    Text("*")
                        .foregroundColor(AppColors.red500)
                }
            }

            Spacer().frame(height: 8)

            // Textbox input with ZStack for layering
            ZStack(alignment: .topLeading) {
                // Background color for TextEditor
                backgroundColor
                    .cornerRadius(12)

                // TextEditor with background removed, to apply custom background
                TextEditor(text: $internalText)
                    .disabled(isDisabled)
                    .foregroundColor(textColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.clear) // Ensure TextEditor itself has no background
                    .cornerRadius(12)
                    .onChange(of: internalText) { _, newValue in
                        text = newValue // Sync with external text binding
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 1)
                            .background(isDisabled ? backgroundColor : .clear)
                    )

                if isDisabled {
                    Text(text)
                        .foregroundColor(AppColors.slate900)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                }

                // Placeholder Text
                if internalText.isEmpty {
                    Text(placeholder)
                        .font(AppTypography.p2)
                        .foregroundColor(AppColors.slate100)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 22)
                        .allowsHitTesting(false) // Allow typing when placeholder is visible
                }
            }

            .frame(height: 100) // Adjustable height for TextBox

            Spacer().frame(height: 8)

            // Description or additional info
            if let description = description {
                Text(description)
                    .font(AppTypography.p3)
                    .foregroundColor(AppColors.slate600)
            }
        }
        .onAppear {
            internalText = text // Initialize internalText with external text binding
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AppTextBox(
            title: "Description",
            placeholder: "Enter your description here...",
            isRequired: true,
            description: "This is a required field",
            isDisabled: false,
            text: .constant("")
        )

        AppTextBox(
            title: "Notes",
            placeholder: "Add your notes",
            isRequired: false,
            description: "Additional information",
            isDisabled: false,
            text: .constant("Some existing content")
        )

        AppTextBox(
            title: "Disabled Field",
            placeholder: "Disabled input",
            isRequired: false,
            description: "This field is disabled",
            isDisabled: true,
            text: .constant("Disabled content")
        )
    }
    .padding()
}
