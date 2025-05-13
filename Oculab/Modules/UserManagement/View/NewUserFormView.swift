//
//  NewUserFormView.swift
//  Oculab
//
//  Created by Risa on 07/05/25.
//

import SwiftUI

struct NewUserFormView: View {
    var body: some View {
        NavigationView {
            ZStack {
                AppPopup(
                    image: "Success",
                    title: "Berhasil membuat Akun",
                    description: "Anda telah berhasil menambahkan akun baru untuk {nama} dengan role {role}",
                    buttons: [
                        AppButton(
                            title: "Buat Akun Lain",
                            colorType: .secondary,
                            size: .large,
                            isEnabled: true
                        ) {},

                        AppButton(
                            title: "Kembali ke Daftar Akun",
                            colorType: .tertiary,
                            isEnabled: true
                        ) {}
                    ],
                    isVisible: .constant(false)
                )

                VStack(spacing: 24) {
                    Image("AddAccount")
                    VStack(spacing: 16) {
                        AppDropdown(
                            title: "Role",
                            placeholder: "Laboran",
                            isRequired: false,
                            leftIcon: "person.fill",
                            rightIcon: "chevron.down",
                            isDisabled: false,
                            choices: [("Laboran", "value1"), ("Admin", "value2")],
                            selectedChoice: .constant("")
                        )
                        AppTextField(
                            title: "Nama",
                            placeholder: "John Doe",
                            text: .constant("")
                        )
                        AppTextField(
                            title: "Emaipl",
                            placeholder: "john@gmail.com",
                            text: .constant("")
                        )
                        AppButton(
                            title: "Daftarkan Akun",
                            rightIcon: "arrow.right",
                            action: {}
                        )
                    }
                    Spacer()
                }
                .padding(.horizontal, Decimal.d20)
                .navigationTitle("Buat Akun Baru")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            Router.shared.navigateBack()
                        }) {
                            HStack {
                                Image("Destroy")
                            }
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NewUserFormView()
}
