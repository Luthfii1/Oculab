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
    @State private var selectedChoice: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Decimal.d8) {
            HStack(spacing: Decimal.d2) {
                Text(title)
                    .font(AppTypography.h4)
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
                            selectedChoice = choice
                        }
                        .padding(2)

                    Text(choice)
                        .font(AppTypography.p2)
                        .foregroundColor(AppColors.slate900)
                        .onTapGesture {
                            selectedChoice = choice
                        }
                }
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        AppRadioButton(
            title: "Gender",
            isRequired: true,
            choices: ["Male", "Female", "Other"]
        )
    }
}
