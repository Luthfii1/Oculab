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
                    VStack(spacing: 52) {
                        VStack(alignment: .leading, spacing: 24) {
                            ValidatedTextField(
                                title: AppTextAuthEditPassword.currentPasswordTitle,
                                placeholder: AppTextAuthEditPassword.currentPasswordPlaceholder,
                                leftIcon: AppIcon.lock,
                                rightIcon: AppIcon.eye,
                                text: $profilePresenter.oldPassword,
                                fieldName: .currentPassword,
                                validationType: .required
                            )

                            ValidatedTextField(
                                title: AppTextAuthEditPassword.newPasswordTitle,
                                placeholder: AppTextAuthEditPassword.newPasswordPlaceholder,
                                leftIcon: AppIcon.lock,
                                rightIcon: AppIcon.eye,
                                text: $profilePresenter.inputPassword,
                                fieldName: .newPassword,
                                validationType: .password
                            )

                            ValidatedTextField(
                                title: AppTextAuthEditPassword.confirmPasswordTitle,
                                placeholder: AppTextAuthEditPassword.confirmPasswordPlaceholder,
                                leftIcon: AppIcon.lock,
                                rightIcon: AppIcon.eye,
                                text: $profilePresenter.confirmPassword,
                                fieldName: .confirmPassword,
                                validationType: .required
                            )
                        }

                        AppButton(
                            title: profilePresenter.saveChangesButtonText,
                            rightIcon: AppIcon.checkmark,
                            isEnabled: profilePresenter.isFormValid
                        ) {
                            Task {
                                await profilePresenter.postEditPasswordWithValidation(authPresenter: DependencyInjection.shared.createAuthPresenter())
                            }
                        }

                        Spacer()
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
    }
}

#Preview {
    EditPasswordView()
        .environmentObject(DependencyInjection.shared.createProfilePresenter())
}
