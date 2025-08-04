//
//  UserAccessPin.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 06/11/24.
//

import SwiftUI

struct UserAccessPin: View {
    @EnvironmentObject var securityPresenter: AuthenticationPresenter
    var state: PinMode
    
    var body: some View {
        NavigationView {
            ZStack {
                if securityPresenter.showAccessPinSuccessPopup {
                    AppPopup(
                        image: AppText.Icon.success,
                        title: AppText.Authentication.UserAccessPin.successTitle,
                        description: AppText.Authentication.UserAccessPin.successDescription,
                        buttons: [
                            AppButton(
                                title: AppText.Authentication.UserAccessPin.successButton,
                                colorType: .secondary,
                                size: .large,
                                isEnabled: true
                            ) {
                                securityPresenter.showAccessPinSuccessPopup = false
                                Router.shared.popToRoot()
                            },
                        ],
                        isVisible: Binding(
                            get: { securityPresenter.showAccessPinSuccessPopup },
                            set: { newValue in
                                if !newValue {
                                    securityPresenter.showAccessPinSuccessPopup = false
                                    Router.shared.popToRoot()
                                }
                            }
                        )
                    )
                }
                
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Text(securityPresenter.descriptionPIN)
                            .font(AppTypography.p2)
                            .foregroundStyle(securityPresenter.textColor)
                            .multilineTextAlignment(.center)
                            .padding(.top, 24)
                            .padding(.horizontal, 20)
                        
                        // PIN circles
                        PINCirclesComponent()
                            .padding(.vertical, 64)
                            .environmentObject(securityPresenter)
                        
                        // Numpad
                        PinNumpadComponent(
                            pin: $securityPresenter.inputPin,
                            state: state
                        )
                        .environmentObject(securityPresenter)
                        
                        Spacer()
                        
                        // Forgot PIN section
                        ForgetPinComponent(state: state)
                    }
                    .padding(.horizontal, 20)
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(securityPresenter.title)
                .toolbar {
                    if state == .revalidate || state == .changePIN {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                Router.shared.navigateBack()
                            }) {
                                HStack {
                                    Image(AppText.Icon.back)
                                }
                            }
                        }
                    }
                }
                .onChange(of: securityPresenter.inputPin) { _, newValue in
                    Task {
                        await securityPresenter.handlePinInput(newValue)
                    }
                }
                .onAppear {
                    securityPresenter.state = state
                    securityPresenter.inputPin.removeAll()
                    securityPresenter.isError = false
                    securityPresenter.checkFaceIDAvailability()
                }
            }
        }
        .hideBackButton()

    }
}

// Preview
#Preview {
    UserAccessPin(state: .authenticate)
        .environmentObject(DependencyInjection.shared.createAuthPresenter())
}
