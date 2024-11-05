//
//  LoginView.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 29/10/24.
//

import SwiftUI

struct LoginView: View {
    @State var username: String = ""
    @State var password: String = ""

    var body: some View {
        VStack {
            Image("LoginImage")

            VStack {
                Text("Revolusi Deteksi Bakteri dengan Teknologi AI").font(AppTypography.h1)

                VStack {
                    AppTextField(
                        title: "Username",
                        placeholder: "Contoh: indrikla24",
                        description: "Dapatkan akun Anda dari admin faskes",
                        text: $username
                    )

                    AppTextField(
                        title: "Kata Sandi",
                        placeholder: "Masukkan Kata Sandi",
                        rightIcon: "eye",
                        text: $password
                    )
                }

                VStack {
                    AppButton(
                        title: "Masuk",
                        colorType: .primary,
                        size: .large
                    ) {}

                    HStack {
                        Text("Faskes belum terdaftar?").font(AppTypography.p3)
                        AppButton(
                            title: "Daftarkan Faskes",
                            colorType: .tertiary,
                            size: .large
                        ) {}
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
