//
//  ForgotPasswordView.swift
//  Oculab
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var presenter: AuthenticationPresenter
    @FocusState private var isEmailFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(AppTextAuthForgotPassword.title)
                        .font(AppTypography.h1)
                        .foregroundStyle(AppColors.slate900)

                    Text(
                        presenter.forgotPasswordSubmitted
                            ? AppTextAuthForgotPassword.successMessage
                            : AppTextAuthForgotPassword.subtitle
                    )
                    .font(AppTypography.p3)
                    .foregroundStyle(AppColors.slate600)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 24)

                if !presenter.forgotPasswordSubmitted {
                    ValidatedTextField(
                        title: AppLabel.email,
                        isRequired: true,
                        placeholder: AppTextAuthLogin.emailPlaceholder,
                        leftIcon: AppIcon.envelope,
                        isDisabled: presenter.isLoading,
                        text: $presenter.forgotPasswordEmail,
                        fieldName: .loginEmail,
                        validationType: .email
                    )
                    .focused($isEmailFocused)

                    if !presenter.forgotPasswordError.isEmpty {
                        Text(presenter.forgotPasswordError)
                            .font(AppTypography.p3)
                            .foregroundStyle(AppColors.red500)
                    }

                    AppButton(
                        title: presenter.isLoading
                            ? AppState.loading
                            : AppTextAuthForgotPassword.submitButton,
                        colorType: .primary,
                        size: .large,
                        isEnabled: !presenter.forgotPasswordEmail.isEmpty && !presenter.isLoading
                    ) {
                        Task {
                            await presenter.requestPasswordReset()
                        }
                    }
                } else {
                    AppButton(
                        title: AppTextAuthForgotPassword.backToLogin,
                        colorType: .primary,
                        size: .large,
                        isEnabled: true
                    ) {
                        presenter.clearForgotPasswordState()
                        Router.shared.navigateBack()
                    }

                    AppButton(
                        title: AppTextAuthForgotPassword.tryAgain,
                        colorType: .tertiary,
                        size: .large,
                        isEnabled: true
                    ) {
                        presenter.clearForgotPasswordState()
                    }
                }
            }
            .padding(.horizontal, AppConstants.defaultPadding)
            .padding(.bottom, 40)
        }
        .dismissKeyboardOnTap()
        .navigationTitle(AppTextAuthForgotPassword.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            presenter.clearForgotPasswordState()
        }
    }
}
