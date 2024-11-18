//
//  LoginView.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 29/10/24.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var presenter: AuthenticationPresenter
    var body: some View {
        NavigationView {
            VStack {
                if !presenter.isKeyboardVisible {
                    Image(.login)
                        .resizable()
                        .scaledToFit()
                        .transition(.opacity)
                }
                VStack {
                    if presenter.isKeyboardVisible {
                        Spacer()
                    }
                    Text("Revolusi Deteksi Bakteri dengan Teknologi AI")
                        .font(AppTypography.h1)
                        .foregroundStyle(AppColors.slate900)
                        .multilineTextAlignment(.center)
                    VStack(spacing: 8) {
                        AppTextField(
                            title: "Email",
                            isRequired: true,
                            placeholder: "Contoh: indrikla24@gmail.com",
                            isError: presenter.isError,
                            text: $presenter.email
                        )
                        AppTextField(
                            title: "Kata Sandi",
                            isRequired: true,
                            placeholder: "Masukkan Kata Sandi",
                            description: presenter.description,
                            rightIcon: "eye",
                            isError: presenter.isError,
                            text: $presenter.password
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    VStack(alignment: .center, spacing: 16) {
                        AppButton(
                            title: presenter.buttonText,
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
                            Text("Faskes belum terdaftar?")
                                .font(AppTypography.p3)
                                .foregroundStyle(AppColors.slate900)
                            AppButton(
                                title: "Daftarkan Faskes",
                                colorType: .tertiary,
                                size: .large
                            ) {
                                print("Daftar faskes button")
                            }
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
