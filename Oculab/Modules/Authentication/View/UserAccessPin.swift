//
//  UserAccessPin.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 06/11/24.
//

import SwiftUI

enum PinMode {
    case create, revalidate, authenticate
}

struct UserAccessPin: View {
    @EnvironmentObject var securityPresenter: AuthenticationPresenter
    var state: PinMode

    var title: String {
        switch state {
        case .create: return "Atur PIN"
        case .revalidate: return "Konfirmasi PIN"
        case .authenticate: return "Masukkan PIN"
        }
    }

    var description: String {
        switch state {
        case .create: return "Atur PIN untuk kemudahan login di sesi berikutnya"
        case .revalidate: return "Masukkan PIN kembali untuk konfirmasi"
        case .authenticate: return "Masukkan PIN untuk mengakses aplikasi"
        }
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .center) {
                Text(description)
                    .font(AppTypography.p2)
                    .foregroundStyle(AppColors.slate900)
                    .padding(.top, 24)
                    .multilineTextAlignment(.center)

                HStack(alignment: .center, spacing: 24) {
                    ForEach(0..<4) { index in
                        Circle()
                            .strokeBorder(AppColors.purple500, lineWidth: 2)
                            .frame(width: 32, height: 32)
                            .background(securityPresenter.inputPin.count > index ? AppColors.purple500 : .clear)
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 64)

                PinNumpadComponent(pin: $securityPresenter.inputPin, isOpeningApp: state == .authenticate)
                    .padding(.top, 40)

                if state == .authenticate {
                    HStack(alignment: .center, spacing: 12) {
                        Text("Lupa PIN?")
                            .font(AppTypography.p3)
                            .foregroundStyle(AppColors.slate900)

                        Text("Gunakan Password")
                            .font(AppTypography.p5)
                            .foregroundStyle(AppColors.purple500)
                    }
                    .padding(.top, 64)
                }

                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: securityPresenter.inputPin) { _, newValue in
                handlePinInput(newValue)
            }
            .navigationBarBackButtonHidden(true)
        }
        .padding(20)
        .ignoresSafeArea(.all)
    }

    private func handlePinInput(_ pin: String) {
        guard pin.count == 4 else { return }

        switch state {
        case .create:
            securityPresenter.firstPin = pin
            securityPresenter.inputPin = ""
            Router.shared.navigateTo(.userAccessPin(state: .revalidate))
        case .revalidate:
            securityPresenter.secondPin = pin
            if securityPresenter.confirmedPin() {
                securityPresenter.setPassword()
                print("PIN set successfully")
            } else {
                print("PINs do not match. Try again.")
                securityPresenter.inputPin = ""
            }
        case .authenticate:
            if securityPresenter.isValidPin() {
                print("Authentication successful")
            } else {
                print("Invalid PIN. Try again.")
                securityPresenter.inputPin = ""
            }
        }
    }
}

#Preview {
    UserAccessPin(state: .create)
}
