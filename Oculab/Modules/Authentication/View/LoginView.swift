//
//  LoginView.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 29/10/24.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authPresenter = AuthenticationPresenter()

    var body: some View {
        NavigationView {
            VStack {
                if !authPresenter.isKeyboardVisible {
                    Image(.login)
                        .resizable()
                        .scaledToFit()
                        .transition(.opacity)
                }

                VStack {
                    if authPresenter.isKeyboardVisible {
                        Spacer()
                    }

                    Text("Revolusi Deteksi Bakteri dengan Teknologi AI")
                        .font(AppTypography.h1)
                        .foregroundStyle(AppColors.slate900)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 8) {
                        AppTextField(
                            title: "Email",
                            placeholder: "Contoh: indrikla24@gmail.com",
                            text: $authPresenter.email
                        )

                        AppTextField(
                            title: "Kata Sandi",
                            placeholder: "Masukkan Kata Sandi",
                            rightIcon: "eye",
                            text: $authPresenter.password
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    VStack(alignment: .center, spacing: 16) {
                        AppButton(
                            title: authPresenter.buttonText,
                            colorType: .primary,
                            size: .large,
                            isEnabled: authPresenter.isFilled()
                        ) {
                            Task {
                                await authPresenter.login()
                            }
                        }

                        HStack(alignment: .center, spacing: 12) {
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

                    if authPresenter.isKeyboardVisible {
                        Spacer()
                    }
                }
                .padding(.top, 24)
                .adaptsToKeyboard(isKeyboardVisible: $authPresenter.isKeyboardVisible)

                Spacer()
            }
            .ignoresSafeArea()
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    LoginView()
}
