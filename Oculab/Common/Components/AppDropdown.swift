//
//  AppDropdown.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 14/10/24.
//

import SwiftUI

struct AppDropdown: View {
    var title: String
    var placeholder: String
    var isRequired: Bool = false
    var leftIcon: String? = nil // SF Symbol or custom icon name
    var rightIcon: String? = "chevron.down" // Default right icon
    var isDisabled: Bool = false
    var choices: [String] // List of dropdown choices
    var isExtended: Bool = false // If true, allows multi-line choices display
    var description: String? = nil // Description or additional info

    @State private var selectedChoice: String? = nil
    @State private var isDropdownOpen: Bool = false

    // Colors based on the state (disabled or normal)
    private var textColor: Color {
        isDisabled ? AppColors.slate400 : AppColors.slate900
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

            // Dropdown button
            Button(action: {
                if !isDisabled {
                    withAnimation {
                        isDropdownOpen.toggle()
                    }
                }
            }) {
                HStack {
                    // Left icon
                    if let leftIcon = leftIcon {
                        Image(systemName: leftIcon)
                            .foregroundColor(AppColors.purple700)
                    }

                    // Placeholder or selected choice
                    Text(selectedChoice ?? placeholder)
                        .foregroundColor(selectedChoice == nil ? AppColors.slate400 : textColor)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Right icon
                    if let rightIcon = rightIcon {
                        Image(systemName: rightIcon)
                            .foregroundColor(textColor)
                    }
                }
                .padding()
                .background(backgroundColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: 1)
                )
            }
            .disabled(isDisabled)

            // Dropdown choices (visible when the dropdown is open)
            if isDropdownOpen {
                VStack(alignment: .leading) {
                    ForEach(choices, id: \.self) { choice in
                        Button(action: {
                            selectedChoice = choice
                            isDropdownOpen = false
                        }) {
                            Text(choice)
                                .foregroundColor(textColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 8)
                        }
                    }
                }
                .frame(maxHeight: isExtended ? .infinity : 150) // Adjustable height based on isExtended
                .padding(.bottom, 12)
                .padding(.top, 4)
                .padding(.horizontal, 16)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: 1)
                )
            }

            Spacer().frame(height: 8)

            // Description or additional info
            if let description = description {
                Text(description)
                    .font(AppTypography.p3)
                    .foregroundColor(AppColors.slate600)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ScrollView {
        AppDropdown(
            title: "Select Option",
            placeholder: "Choose an option...",
            isRequired: true,
            leftIcon: "list.bullet",
            rightIcon: "chevron.down",
            isDisabled: false,
            choices: ["Option 1", "Option 2", "Option 3", "Option 4"],
            isExtended: false,
            description: "Please select an option from the dropdown"
        )

        AppDropdown(
            title: "Disabled Dropdown",
            placeholder: "Disabled",
            isRequired: false,
            leftIcon: "lock.fill",
            rightIcon: "chevron.down",
            isDisabled: true,
            choices: ["Option A", "Option B"],
            isExtended: false,
            description: "This dropdown is disabled"
        )

        AppDropdown(
            title: "Extended Dropdown",
            placeholder: "Choose something...",
            isRequired: true,
            leftIcon: "arrow.down.to.line.alt",
            rightIcon: "chevron.up",
            isDisabled: false,
            choices: [
                "Extended Option 1",
                "Extended Option 2",
                "Extended Option 3",
                "Extended Option 4",
                "Extended Option 5",
                "Extended Option 6"
            ],
            isExtended: true,
            description: "This dropdown allows more options to be visible."
        )
    }
    .padding()
}
