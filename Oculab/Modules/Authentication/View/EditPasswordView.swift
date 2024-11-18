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
            ScrollView(showsIndicators: false) {
                VStack(spacing: 52) {
                    VStack(alignment: .leading, spacing: 24) {
                        AppTextField(
                            title: "Password Saat Ini",
                            placeholder: "Masukkan Password",
                            description: profilePresenter.descriptionOldPassword,
                            rightIcon: "eye",
                            isError: profilePresenter.isOldPasswordError,
                            text: $profilePresenter.oldPassword
                        )

                        AppTextField(
                            title: "Password Baru",
                            placeholder: "Masukkan Password Baru",
                            description: "Password harus terdiri dari minimal 8 karakter",
                            rightIcon: "eye",
                            text: $profilePresenter.inputPassword
                        )

                        AppTextField(
                            title: "Konfirmasi Password Baru",
                            placeholder: "Masukkan Konfirmasi Password Baru",
                            description: profilePresenter.descriptionPasswordConfirm,
                            rightIcon: "eye",
                            isError: profilePresenter.isError,
                            text: $profilePresenter.confirmPassword
                        )
                    }

                    AppButton(
                        title: profilePresenter.buttonText,
                        rightIcon: "checkmark",
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
            .navigationTitle("Atur Password")
            .toolbar {
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
        .hideBackButton()
    }
}

#Preview {
    EditPasswordView()
        .environmentObject(DependencyInjection.shared.createProfilePresenter())
}
