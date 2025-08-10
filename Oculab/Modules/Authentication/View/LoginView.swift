//
//  LoginView.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 29/10/24.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var presenter: AuthenticationPresenter
    @StateObject private var contactPresenter = ContactPresenter(interactor: ContactInteractor())

    var body: some View {
        NavigationView {
            VStack {
                if !presenter.isKeyboardVisible {
                    Image(AppImage.login)
                        .resizable()
                        .scaledToFit()
                        .transition(.opacity)
                }
                VStack {
                    if presenter.isKeyboardVisible {
                        Spacer()
                    }
                    Text(AppTextAuthLogin.title)
                        .font(AppTypography.h1)
                        .foregroundStyle(AppColors.slate900)
                        .multilineTextAlignment(.center)
                    VStack(spacing: 8) {
                        AppTextField(
                            title: AppLabel.email,
                            isRequired: true,
                            placeholder: AppTextAuthLogin.emailPlaceholder,
                            isError: presenter.isError,
                            isDisabled: presenter.isLoading,
                            text: $presenter.email
                        )
                        AppTextField(
                            title: AppLabel.password,
                            isRequired: true,
                            placeholder: AppTextAuthLogin.passwordPlaceholder,
                            description: presenter.description,
                            rightIcon: AppIcon.eye,
                            isError: presenter.isError,
                            isDisabled: presenter.isLoading,
                            text: $presenter.password
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    VStack(alignment: .center, spacing: 16) {
                        AppButton(
                            title: presenter.loginButtonText, 
                            colorType: .primary,
                            size: .large,
                            isEnabled: presenter.isFilled
                        ) {
                            Task {
                                await presenter.login()
                                await presenter.getAccountById()
                            }
                        }
                        HStack {
                            Spacer()
                            Text(AppTextAuthLogin.faskesNotRegisteredYet)
                                .font(AppTypography.p3)
                                .foregroundStyle(AppColors.slate900)
                            AppButton(
                                title: AppTextAuthLogin.registerFaskesButtonText,
                                colorType: .tertiary,
                                size: .large,
                                isEnabled: true
                            ) {
                                Task {
                                    await contactPresenter.directToWhatsapp()
                                }
                            }
                            .multilineTextAlignment(.leading)
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 18)
                    if presenter.isKeyboardVisible {
                        Spacer()
                    }
                }
                .padding(.top, 24)
                .adaptsToKeyboard(isKeyboardVisible: $presenter.isKeyboardVisible)
                Spacer()
            }
            .ignoresSafeArea()
        }
        .onAppear {
            presenter.clearInput()
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    LoginView()
        .environmentObject(DependencyInjection.shared.createAuthPresenter())
}
