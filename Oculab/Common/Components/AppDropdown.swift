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
    var choices: [(display: String, value: String)] // List of dropdown choices with display and value
    var description: String? = nil // Description or additional info
    @Binding var selectedChoice: String

    @State private var isDropdownOpen: Bool = false
    @State private var searchText: String = "" // New state for search text
    @State var isEnablingAdding: Bool = false

    // Computed property to filter choices based on search text
    private var filteredChoices: [(display: String, value: String)] {
        choices.filter { $0.display.localizedCaseInsensitiveContains(searchText) || searchText.isEmpty }
    }

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
                        searchText = "" // Reset search when dropdown is opened
                    }
                }
            }) {
                HStack(spacing: Decimal.d4) {
                    HStack(alignment: .center) { // Set alignment here
                        if let leftIcon = leftIcon {
                            Image(systemName: leftIcon)
                                .foregroundColor(AppColors.purple700)
                        }

                        TextField(placeholder, text: $searchText, onEditingChanged: { editing in
                            if editing {
                                isDropdownOpen = true
                            }
                        })
                        .foregroundColor(textColor)
                        .disabled(isDisabled)
                        .padding(.horizontal, Decimal.d8)
                        .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let rightIcon = rightIcon {
                        Image(systemName: rightIcon)
                            .foregroundColor(textColor)
                    }
                }
                .onChange(of: selectedChoice) {
                    // Update search text based on selected choice display value
                    searchText = choices.first(where: { $0.value == selectedChoice })?.display ?? selectedChoice
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

            // Dropdown choices (visible when the dropdown is open and filtered by search)
            if isDropdownOpen {
                VStack(alignment: .leading) {
                    if isEnablingAdding {
                        Button {
                            isDropdownOpen = false
                            selectedChoice = searchText
                        } label: {
                            HStack {
                                Text("Tambahkan").font(AppTypography.p2).foregroundStyle(AppColors.purple500)
                                    .bold()
                                Text("\"\(searchText)\"").foregroundStyle(AppColors.slate900)

                            }.padding(.top, 8)
                        }
                    }

                    ScrollView {
                        if filteredChoices.isEmpty {
                            Text("Tidak ada data yang sesuai")
                                .foregroundColor(AppColors.slate100)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 8)

                        } else {
                            ForEach(filteredChoices, id: \.value) { choice in
                                Button(action: {
                                    selectedChoice = choice.value
                                    searchText = choice.display
                                    isDropdownOpen = false
                                }) {
                                    Text(choice.display)
                                        .foregroundColor(textColor)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, 8)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 150)
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
            choices: [("Option 1", "value1"), ("Option 2", "value2"), ("Option 3", "value3"), ("Option 4", "value4")],
            description: "Please select an option from the dropdown",
            selectedChoice: .constant("")
        )
    }
    .padding()
}
