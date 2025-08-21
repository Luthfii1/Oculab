//
//  ActivateFaceIdView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 21/08/25.
//

import SwiftUI

struct ActivateFaceIdView: View {
    @EnvironmentObject var securityPresenter: AuthenticationPresenter
    
    var body: some View {
        NavigationView {
            VStack(spacing: 18) {
                Text(AppTextAuthBiometric.activateBiometricDescription)
                    .font(AppTypography.p2)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                    .padding(.horizontal, 20)
                
                Image(AppImage.activateFaceId)
                    .resizable()
                    .frame(width: 200, height: 200)
                
                Spacer()
                
                VStack(spacing: 12) {
                    AppButton(
                        title: AppTextAuthBiometric.activateBiometricEnableButtonText,
                        colorType: .primary,
                        size: .large,
                        isEnabled: true
                    ) {
                        Task {
                            await securityPresenter.activateFaceIdFirstTime()
                        }
                    }
                    
                    AppButton(
                        title: AppTextAuthBiometric.activateBiometricCancelButtonText,
                        colorType: .secondary,
                        size: .large,
                        isEnabled: true
                    ) {
                        securityPresenter.skipFaceIdActivation()
                    }
                }
            }
            .padding(.horizontal, 20)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(AppTextAuthBiometric.activateBiometricTitle)
        }
        .hideBackButton()
    }
}

#Preview {
    ActivateFaceIdView()
        .environmentObject(DependencyInjection.shared.createAuthPresenter())
}
