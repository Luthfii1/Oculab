//
//  EditPasswordView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/11/24.
//

import SwiftUI

struct EditPasswordView: View {
    @EnvironmentObject private var profilePresenter: ProfilePresenter

    var body: some View {
        NavigationView {
            ZStack {
                if profilePresenter.showSuccessPopup {
                    AppPopup(
                        image: AppImage.success,
                        title: AppTextAuthEditPassword.successUpdatePasswordTitle,
                        description: AppTextAuthEditPassword.successUpdatePasswordMessage,
                        buttons: [
                            AppButton(
                                title: AppTextAuthEditPassword.successUpdatePasswordButtonText,
                                colorType: .secondary,
                                size: .large,
                                isEnabled: true
                            ) {
                                profilePresenter.backToProfilePage()
                            },
                        ],
                        isVisible: Binding(
                            get: { profilePresenter.showSuccessPopup },
                            set: { newValue in
                                if !newValue {
                                    profilePresenter.backToProfilePage()
                                }
                            }
                        )
                    )
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        Text(AppTextAuthEditPassword.newPasswordDescription)
                            .font(AppTypography.p2)
                            .foregroundStyle(AppColors.slate500)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if !profilePresenter.generalFormError.isEmpty {
                            PasswordFormBanner(
                                message: profilePresenter.generalFormError,
                                style: .error
                            )
                        }

                        VStack(alignment: .leading, spacing: 24) {
                            ValidatedTextField(
                                title: AppTextAuthEditPassword.currentPasswordTitle,
                                isRequired: true,
                                placeholder: AppTextAuthEditPassword.currentPasswordPlaceholder,
                                leftIcon: AppIcon.lock,
                                rightIcon: AppIcon.eye,
                                text: $profilePresenter.oldPassword,
                                fieldName: .currentPassword,
                                validationType: .required,
                                validateOnChange: false
                            )

                            VStack(alignment: .leading, spacing: 8) {
                                ValidatedTextField(
                                    title: AppTextAuthEditPassword.newPasswordTitle,
                                    isRequired: true,
                                    placeholder: AppTextAuthEditPassword.newPasswordPlaceholder,
                                    leftIcon: AppIcon.lock,
                                    rightIcon: AppIcon.eye,
                                    text: $profilePresenter.inputPassword,
                                    fieldName: .newPassword,
                                    validationType: .password,
                                    validateOnChange: false
                                )

                                Text(AppTextAuthEditPassword.newPasswordDescription)
                                    .font(AppTypography.p3)
                                    .foregroundStyle(AppColors.slate500)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                ValidatedTextField(
                                    title: AppTextAuthEditPassword.confirmPasswordTitle,
                                    isRequired: true,
                                    placeholder: AppTextAuthEditPassword.confirmPasswordPlaceholder,
                                    leftIcon: AppIcon.lock,
                                    rightIcon: AppIcon.eye,
                                    text: $profilePresenter.confirmPassword,
                                    fieldName: .confirmPassword,
                                    validationType: .none,
                                    validateOnChange: false
                                )

                                Text(profilePresenter.confirmPasswordHint)
                                    .font(AppTypography.p3)
                                    .foregroundStyle(
                                        profilePresenter.confirmPasswordHintIsError
                                            ? AppColors.red500
                                            : (profilePresenter.confirmPasswordHint == AppTextAuthProfile.confirmPasswordSuccess
                                                ? AppColors.green600
                                                : AppColors.slate500)
                                    )
                            }
                        }

                        AppButton(
                            title: profilePresenter.saveChangesButtonText,
                            rightIcon: AppIcon.checkmark,
                            isEnabled: profilePresenter.isFormValid
                        ) {
                            Task {
                                await profilePresenter.postEditPasswordWithValidation(
                                    authPresenter: DependencyInjection.shared.createAuthPresenter()
                                )
                            }
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(20)
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(AppTextAuthEditPassword.navigationTitle)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            Router.shared.navigateBack()
                        }) {
                            HStack {
                                Image(AppImage.back)
                            }
                        }
                    }
                }
            }
        }
        .hideBackButton()
        .onAppear {
            profilePresenter.preparePasswordEditForm()
        }
    }
}

private struct PasswordFormBanner: View {
    enum Style {
        case error
    }

    let message: String
    let style: Style

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: AppIcon.alert)
                .foregroundStyle(AppColors.red500)

            Text(message)
                .font(AppTypography.p3)
                .foregroundStyle(AppColors.red500)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(AppColors.red50)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    EditPasswordView()
        .environmentObject(DependencyInjection.shared.createProfilePresenter())
}
