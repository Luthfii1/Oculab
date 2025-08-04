//
//  ForgetPinComponent.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 14/11/24.
//

import SwiftUI

struct ForgetPinComponent: View {
    var state: PinMode
    var body: some View {
        if state == .authenticate {
            HStack(alignment: .center, spacing: 8) {
                Text(AppTextAuthCompPin.forgotPinText)
                    .font(AppTypography.p3)
                    .foregroundStyle(AppColors.slate900)

                AppButton(
                    title: AppTextAuthCompPin.usePasswordButton, 
                    colorType: .tertiary
                ) {
                    print("Use password tapped")
                }
            }
        }
    }
}

#Preview {
    ForgetPinComponent(state: .authenticate)
}
