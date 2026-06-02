//
//  AppDropdown.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 14/10/24.
//

import SwiftUI
import UIKit

struct AppDropdown: View {
    var title: String
    var placeholder: String
    var isRequired: Bool = false
    var leftIcon: String? = nil // SF Symbol or custom icon name
    var rightIcon: String? = AppIcon.down // Default right icon
    var isDisabled: Bool = false
    var choices: [(display: String, value: String)] // List of dropdown choices with display and value
    var description: String? = nil // Description or additional info
    var emptyListMessage: String? = nil // Shown when there are no choices (e.g. first-time empty list)
    var isSearchEnabled: Bool = true // New parameter to control search functionality
    @Binding var selectedChoice: String

    @State private var isDropdownOpen: Bool = false
    @State private var searchText: String = AppValue.empty // New state for search text
    @State var isEnablingAdding: Bool = false

    // Computed property to filter choices based on search text and sort alphabetically
    private var filteredChoices: [(display: String, value: String)] {
        let sorted = choices.sorted { $0.display.localizedCaseInsensitiveCompare($1.display) == .orderedAscending }
        
        if isSearchEnabled {
            return sorted.filter { $0.display.localizedCaseInsensitiveContains(searchText) || searchText.isEmpty }
        }
        return sorted
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
                    Text(AppValue.required)
                        .foregroundColor(AppColors.red500)
                }
            }

            Spacer().frame(height: 8)

            // Dropdown button
            Button(action: {
                if !isDisabled {
                    withAnimation {
                        if isDropdownOpen {
                            isDropdownOpen = false
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil,
                                from: nil,
                                for: nil
                            )
                        } else {
                            if isSearchEnabled {
                                syncSearchTextWithSelection()
                            }
                            isDropdownOpen = true
                        }
                    }
                }
            }) {
                HStack(spacing: Decimal.d4) {
                    HStack(alignment: .center) { // Set alignment here
                        if let leftIcon = leftIcon, !leftIcon.isEmpty {
                            Image(systemName: leftIcon)
                                .foregroundColor(AppColors.purple700)
                        }

                        if isSearchEnabled {
                            TextField(placeholder, text: $searchText, onEditingChanged: { editing in
                                if editing {
                                    if !isDropdownOpen {
                                        syncSearchTextWithSelection()
                                    }
                                    isDropdownOpen = true
                                }
                            })
                            .foregroundColor(textColor)
                            .disabled(isDisabled)
                            .padding(.horizontal, Decimal.d8)
                            .multilineTextAlignment(.leading)
                        } else {
                            Text(selectedChoice.isEmpty ? placeholder : choices.first(where: { $0.value == selectedChoice })?.display ?? selectedChoice)
                                .foregroundColor(textColor)
                                .padding(.horizontal, Decimal.d8)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let rightIcon = rightIcon, !rightIcon.isEmpty, !isDisabled {
                        Image(systemName: rightIcon)
                            .foregroundColor(textColor)
                    }
                }
                .onChange(of: selectedChoice) {
                    // Update search text based on selected choice display value
                    if isSearchEnabled {
                        searchText = choices.first(where: { $0.value == selectedChoice })?.display ?? selectedChoice
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

            // Dropdown choices (visible when the dropdown is open and filtered by search)
            if isDropdownOpen {
                VStack(alignment: .leading) {
                    if isSearchEnabled && isEnablingAdding && !trimmedSearchText.isEmpty {
                        Button {
                            isDropdownOpen = false
                            selectedChoice = trimmedSearchText
                            searchText = trimmedSearchText
                        } label: {
                            HStack {
                                Text(AppAction.addNew).font(AppTypography.p2).foregroundStyle(AppColors.purple500)
                                    .bold()
                                Text(AppSearch.resultFor(searchText)).foregroundStyle(AppColors.slate900)

                            }.padding(.top, 8)
                        }
                    }

                    ScrollView {
                        if filteredChoices.isEmpty {
                            Text(emptyDropdownMessage)
                                .font(AppTypography.p3)
                                .foregroundColor(AppColors.slate400)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 8)
                                .multilineTextAlignment(.center)

                        } else {
                            ForEach(filteredChoices, id: \.value) { choice in
                                Button(action: {
                                    selectedChoice = choice.value
                                    if isSearchEnabled {
                                        searchText = choice.display
                                    }
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

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var emptyDropdownMessage: String {
        if choices.isEmpty, let emptyListMessage, !emptyListMessage.isEmpty {
            return emptyListMessage
        }
        if isSearchEnabled && isEnablingAdding && trimmedSearchText.isEmpty {
            return AppSearch.Patient.typeToAddHint
        }
        return AppSearch.noResults
    }

    private func syncSearchTextWithSelection() {
        guard !selectedChoice.isEmpty else {
            searchText = AppValue.empty
            return
        }
        searchText = choices.first(where: { $0.value == selectedChoice })?.display ?? selectedChoice
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Preview with search enabled
            AppDropdown(
                title: "Searchable Dropdown",
                placeholder: "Choose an option...",
                isRequired: true,
                leftIcon: "list.bullet",
                rightIcon: "chevron.down",
                isDisabled: false,
                choices: [("Option 1", "value1"), ("Option 2", "value2"), ("Option 3", "value3"), ("Option 4", "value4")],
                description: "This dropdown has search functionality",
                isSearchEnabled: true,
                selectedChoice: .constant("")
            )
            
            // Preview with search disabled
            AppDropdown(
                title: "Normal Dropdown",
                placeholder: "Choose an option...",
                isRequired: true,
                leftIcon: "list.bullet",
                rightIcon: "chevron.down",
                isDisabled: false,
                choices: [("Option 1", "value1"), ("Option 2", "value2"), ("Option 3", "value3"), ("Option 4", "value4")],
                description: "This is a normal dropdown without search",
                isSearchEnabled: false,
                selectedChoice: .constant("")
            )
        }
    }
    .padding()
}
