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
                            AppTextField(
                                title: AppTextAuthEditPassword.currentPasswordTitle,
                                placeholder: AppTextAuthEditPassword.currentPasswordPlaceholder,
                                description: profilePresenter.descriptionOldPassword,
                                rightIcon: AppIcon.eye,
                                isError: profilePresenter.isOldPasswordError,
                                text: $profilePresenter.oldPassword
                            )

                            AppTextField(
                                title: AppTextAuthEditPassword.newPasswordTitle,
                                placeholder: AppTextAuthEditPassword.newPasswordPlaceholder,
                                description: AppTextAuthEditPassword.newPasswordDescription,
                                rightIcon: AppIcon.eye,
                                text: $profilePresenter.inputPassword
                            )

                            AppTextField(
                                title: AppTextAuthEditPassword.confirmPasswordTitle,
                                placeholder: AppTextAuthEditPassword.confirmPasswordPlaceholder,
                                description: profilePresenter.descriptionPasswordConfirm,
                                rightIcon: AppIcon.eye,
                                isError: profilePresenter.isError,
                                text: $profilePresenter.confirmPassword
                            )
                        }

                        AppButton(
                            title: profilePresenter.saveChangesButtonText,
                            rightIcon: AppIcon.checkmark,
                            isEnabled: profilePresenter.isPasswordEditButtonEnabled()
                        ) {
                            Task {
                                await profilePresenter
                                    .postEditPassword(authPresenter: DependencyInjection.shared.createAuthPresenter())
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
