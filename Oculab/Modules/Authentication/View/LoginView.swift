//
//  LoginView.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 29/10/24.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var presenter: AuthenticationPresenter
    @StateObject private var contactPresenter = ContactPresenter(interactor: ContactInteractor())

    @State private var contactId: String = "7b4e28ba-23a1-1cd4-183f-0016d3cca420"

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
                            title: "Username",
                            isRequired: true,
                            placeholder: "Contoh: indrikla",
                            isError: presenter.isError,
                            text: $presenter.username
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
                                size: .large,
                                isEnabled: true
                            ) {
                                Task {
                                    await contactPresenter.fetchData(contactId: contactId)

                                    if let url = URL(string: contactPresenter.contactData.whatsappLink) {
                                        await MainActor.run {
                                            UIApplication.shared.open(url)
                                            print("Fetched WhatsApp URL: \(url)")
                                        }
                                    } else {
                                        print("Invalid WhatsApp URL: ", contactPresenter.contactData.whatsappLink)
                                    }
                                }
                            }
                            .multilineTextAlignment(.leading)
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
