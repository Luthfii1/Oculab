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
                        title: AppText.Authentication.EditPasswordView.successUpdatePasswordTitle,
                        description: AppText.Authentication.EditPasswordView.successUpdatePasswordMessage,
                        buttons: [
                            AppButton(
                                title: AppText.Authentication.EditPasswordView.successUpdatePasswordButtonText,
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
                                title: AppText.Authentication.EditPasswordView.currentPasswordTitle,
                                placeholder: AppText.Authentication.EditPasswordView.currentPasswordPlaceholder,
                                description: profilePresenter.descriptionOldPassword,
                                rightIcon: AppText.Icon.eye,
                                isError: profilePresenter.isOldPasswordError,
                                text: $profilePresenter.oldPassword
                            )

                            AppTextField(
                                title: AppText.Authentication.EditPasswordView.newPasswordTitle,
                                placeholder: AppText.Authentication.EditPasswordView.newPasswordPlaceholder,
                                description: AppText.Authentication.EditPasswordView.newPasswordDescription,
                                rightIcon: AppText.Icon.eye,
                                text: $profilePresenter.inputPassword
                            )

                            AppTextField(
                                title: AppText.Authentication.EditPasswordView.confirmPasswordTitle,
                                placeholder: AppText.Authentication.EditPasswordView.confirmPasswordPlaceholder,
                                description: profilePresenter.descriptionPasswordConfirm,
                                rightIcon: AppText.Icon.eye,
                                isError: profilePresenter.isError,
                                text: $profilePresenter.confirmPassword
                            )
                        }

                        AppButton(
                            title: AppText.Authentication.ProfileView.saveChangesButton,
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
                .navigationTitle(AppText.Authentication.EditPasswordView.navigationTitle)
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
