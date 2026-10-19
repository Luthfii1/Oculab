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
                    Text(AppValue.required)
                        .font(AppTypography.h4)
                        .foregroundColor(.red)
                }
            }

            ForEach(choices, id: \.self) { choice in
                Button {
                    selectedChoice = choice
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: selectedChoice == choice ? AppIcon.largecircleFillCircle : AppIcon.circle)
                            .font(.system(size: 20))
                            .foregroundColor(selectedChoice == choice ? AppColors.purple600 : AppColors.slate400)
                            .accessibilityHidden(true)
                        Text(choice)
                            .font(AppTypography.p2)
                            .foregroundColor(AppColors.slate900)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .background(selectedChoice == choice ? AppColors.purple50 : AppColors.slate0)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selectedChoice == choice ? AppColors.purple300 : AppColors.slate200, lineWidth: 1)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
                .accessibilityAddTraits(selectedChoice == choice ? .isSelected : [])
            }
        }
        .opacity(isDisabled ? 0.6 : 1.0) // Optional: dim appearance when disabled
    }
}

struct AppRadioButtonPreview: View {
    @State private var sex = AppValue.empty
    @State private var isDisabled = false

    var body: some View {
        VStack(alignment: .leading) {
            AppRadioButton(
                title: AppPatient.gender,
                isRequired: true,
                choices: [AppPatient.Gender.male, AppPatient.Gender.female, AppPatient.Gender.other],
                isDisabled: isDisabled,
                selectedChoice: $sex
            )
            .padding()

            Toggle(AppAction.disable(AppFeature.radioButton), isOn: $isDisabled)
                .padding()
        }
    }
}

#Preview {
    AppRadioButtonPreview()
}
