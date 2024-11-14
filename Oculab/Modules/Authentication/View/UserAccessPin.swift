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
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Text(securityPresenter.description)
                        .font(AppTypography.p2)
                        .foregroundStyle(AppColors.slate900)
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
                        isOpeningApp: state == .authenticate
                    )

                    Spacer()

                    // Forgot PIN section
                    ForgetPinComponent(state: state)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(securityPresenter.title)
            .toolbar {
                if state == .revalidate {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            Router.shared.navigateBack()
                        }) {
                            HStack {
                                Image("back")
                            }
                        }
                    }
                }
            }
            .onChange(of: securityPresenter.inputPin) { _, newValue in
                securityPresenter.handlePinInput(newValue)
            }
            .onAppear {
                securityPresenter.state = state
                securityPresenter.inputPin.removeAll()
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
