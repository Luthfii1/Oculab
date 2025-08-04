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
                        image: AppText.Icon.success,
                        title: AppText.Authentication.EditPassword.successUpdatePasswordTitle,
                        description: AppText.Authentication.EditPassword.successUpdatePasswordMessage,
                        buttons: [
                            AppButton(
                                title: AppText.Authentication.EditPassword.successUpdatePasswordButtonText,
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
                                title: AppText.Authentication.EditPassword.currentPasswordTitle,
                                placeholder: AppText.Authentication.EditPassword.currentPasswordPlaceholder,
                                description: profilePresenter.descriptionOldPassword,
                                rightIcon: AppText.Icon.eye,
                                isError: profilePresenter.isOldPasswordError,
                                text: $profilePresenter.oldPassword
                            )

                            AppTextField(
                                title: AppText.Authentication.EditPassword.newPasswordTitle,
                                placeholder: AppText.Authentication.EditPassword.newPasswordPlaceholder,
                                description: AppText.Authentication.EditPassword.newPasswordDescription,
                                rightIcon: AppText.Icon.eye,
                                text: $profilePresenter.inputPassword
                            )

                            AppTextField(
                                title: AppText.Authentication.EditPassword.confirmPasswordTitle,
                                placeholder: AppText.Authentication.EditPassword.confirmPasswordPlaceholder,
                                description: profilePresenter.descriptionPasswordConfirm,
                                rightIcon: AppText.Icon.eye,
                                isError: profilePresenter.isError,
                                text: $profilePresenter.confirmPassword
                            )
                        }

                        AppButton(
                            title: profilePresenter.buttonText,
                            rightIcon: AppText.Icon.checkmark,
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
                .navigationTitle(AppText.Authentication.EditPassword.navigationTitle)
                .toolbar {
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
        }
        .hideBackButton()
    }
}

#Preview {
    EditPasswordView()
        .environmentObject(DependencyInjection.shared.createProfilePresenter())
}
