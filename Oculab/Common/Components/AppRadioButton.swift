//
//  AppRadioButton.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import SwiftUI

struct AppRadioButton: View {
    var title: String
    var isRequired: Bool
    var choices: [String]
    var isDisabled: Bool
    @Binding var selectedChoice: String

    var body: some View {
        VStack(alignment: .leading, spacing: Decimal.d8) {
            HStack(spacing: Decimal.d2) {
                Text(title)
                    .font(AppTypography.s4_1)
                    .foregroundColor(AppColors.slate900)

                if isRequired {
                    Text("*")
                        .font(AppTypography.h4)
                        .foregroundColor(.red)
                }
            }

            ForEach(choices, id: \.self) { choice in
                HStack(spacing: Decimal.d4) {
                    Image(systemName: selectedChoice == choice ? "largecircle.fill.circle" : "circle")
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(selectedChoice == choice ? AppColors.purple600 : .gray)
                        .onTapGesture {
                            if !isDisabled {
                                selectedChoice = choice
                            }
                        }
                        .padding(2)

                    Text(choice)
                        .font(AppTypography.p2)
                        .foregroundColor(isDisabled ? .gray : AppColors.slate900)
                        .onTapGesture {
                            if !isDisabled {
                                selectedChoice = choice
                            }
                        }
                }
            }
        }
        .opacity(isDisabled ? 0.6 : 1.0) // Optional: dim appearance when disabled
    }
}

struct AppRadioButtonPreview: View {
    @State private var sex = ""
    @State private var isDisabled = false

    var body: some View {
        VStack(alignment: .leading) {
            AppRadioButton(
                title: "Gender",
                isRequired: true,
                choices: ["Male", "Female", "Other"],
                isDisabled: isDisabled,
                selectedChoice: $sex
            )
            .padding()

            Toggle("Disable Radio Buttons", isOn: $isDisabled)
                .padding()
        }
    }
}

#Preview {
    AppRadioButtonPreview()
}
