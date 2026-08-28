//
//  LoginView.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 29/10/24.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var presenter: AuthenticationPresenter
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    if !presenter.isKeyboardVisible {
                        Image(AppImage.login)
                            .resizable()
                            .scaledToFit()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale),
                                removal: .opacity.combined(with: .scale)
                            ))
                            .animation(.easeInOut(duration: AppConstants.animationDuration), value: presenter.isKeyboardVisible)
                    }
                    VStack {
                        if presenter.isKeyboardVisible {
                            Spacer(minLength: AppConstants.loginKeyboardTopSpacing) // Add some top spacing when keyboard is visible
                        }
                        Text(AppTextAuthLogin.title)
                            .font(AppTypography.h1)
                            .foregroundStyle(AppColors.slate900)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        VStack(spacing: 8) {
                            ValidatedTextField(
                                title: AppLabel.email,
                                isRequired: true,
                                placeholder: AppTextAuthLogin.emailPlaceholder,
                                leftIcon: AppIcon.envelope,
                                isDisabled: presenter.isLoading,
                                text: $presenter.email,
                                fieldName: .loginEmail,
                                validationType: .email
                            )
                            .focused($isEmailFocused)
                            
                            ValidatedTextField(
                                title: AppLabel.password,
                                isRequired: true,
                                placeholder: AppTextAuthLogin.passwordPlaceholder,
                                leftIcon: AppIcon.lock,
                                rightIcon: AppIcon.eye,
                                isDisabled: presenter.isLoading,
                                text: $presenter.password,
                                fieldName: .loginPassword,
                                validationType: .password
                            )
                            .focused($isPasswordFocused)

                            HStack {
                                Spacer()
                                AppButton(
                                    title: AppTextAuthLogin.forgotPassword,
                                    colorType: .tertiary,
                                    size: .large,
                                    isEnabled: true
                                ) {
                                    Router.shared.navigateTo(.forgotPassword)
                                }
                                .accessibilityLabel(AppTextAuthLogin.forgotPassword)
                            }
                        }
                        .padding(.horizontal, AppConstants.defaultPadding)
                        .padding(.top, AppConstants.loginFieldsTopPadding)

                        VStack(alignment: .center, spacing: 16) {
                            AppButton(
                                title: presenter.loginButtonText, 
                                colorType: .primary,
                                size: .large,
                                isEnabled: presenter.isFilled
                            ) {
                                Task {
                                    await presenter.handleLogin()
                                }
                            }
                            .accessibilityLabel(AppTextAuthLogin.buttonText)
                            HStack {
                                Spacer()
                                Text(AppTextAuthLogin.dontHaveAccount)
                                    .font(AppTypography.p3)
                                    .foregroundStyle(AppColors.slate900)
                                AppButton(
                                    title: AppTextAuthLogin.registerAccountButtonText,
                                    colorType: .tertiary,
                                    size: .large,
                                    isEnabled: true
                                ) {
                                    Task {
                                        Router.shared.navigateTo(.register)
                                    }
                                }
                                .accessibilityLabel(AppTextAuthLogin.registerAccountButtonText)
                                .multilineTextAlignment(.leading)
                                Spacer()
                            }
                        }
                        .padding(.horizontal, AppConstants.defaultPadding)
                        .padding(.top, AppConstants.loginButtonTopPadding)
                        Spacer(minLength: AppConstants.loginBottomSpacing) // Add bottom spacing for keyboard
                    }
                    .padding(.top, presenter.isKeyboardVisible ? AppConstants.loginContentPaddingKeyboard : AppConstants.loginContentPaddingNormal)
                }
            }
            .ignoresSafeArea()
            .dismissKeyboardOnTap()
        }
        .onAppear {
            presenter.clearInput()
        }
        .onChange(of: isEmailFocused) { _, focused in
            withAnimation(.easeInOut(duration: AppConstants.animationDuration)) {
                presenter.isKeyboardVisible = focused || isPasswordFocused
            }
        }
        .onChange(of: isPasswordFocused) { _, focused in
            withAnimation(.easeInOut(duration: AppConstants.animationDuration)) {
                presenter.isKeyboardVisible = isEmailFocused || focused
            }
        }
        .navigationBarBackButtonHidden()
        // Error alert for login failures
        .alert(
            AppTextAuthLogin.loginFailedText,
            isPresented: Binding(
                get: { presenter.isError && !presenter.description.isEmpty },
                set: { if !$0 { 
                    presenter.isError = false
                    presenter.description = AppValue.empty
                } }
            ),
            actions: {
                Button(AppAction.ok) {
                    presenter.isError = false
                    presenter.description = AppValue.empty
                }
            },
            message: {
                Text(presenter.description)
            }
        )
    }
}

//#Preview {
//    LoginView()
//        .environmentObject(DependencyInjection.shared.createAuthPresenter())
//}
