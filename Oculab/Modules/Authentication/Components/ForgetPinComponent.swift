//
//  ForgetPinComponent.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 14/11/24.
//

import SwiftUI

struct ForgetPinComponent: View {
    @EnvironmentObject var authPresenter: AuthenticationPresenter
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
                    Logger.debug("Use password button tapped", category: .authentication)
                    authPresenter.showForgetPinPopup = true
                }
            }
        }
    }
}

#Preview {
    ForgetPinComponent(state: .authenticate)
        .environmentObject(DependencyInjection.shared.createAuthPresenter())
}
