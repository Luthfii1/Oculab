//
//  NewUserFormView.swift
//  Oculab
//
//  Created by Risa on 07/05/25.
//

import SwiftUI

struct NewUserFormView: View {
    @StateObject private var presenter = AccountPresenter()
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var role: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Success popup
                if presenter.showSuccessPopup {
                    AppPopup(
                        image: "Success",
                        title: "Berhasil membuat Akun",
                        description: "Anda telah berhasil menambahkan akun baru untuk \(presenter.successInfo.name) dengan role \(presenter.successInfo.role)",
                        buttons: [
                            AppButton(
                                title: "Buat Akun Lain",
                                colorType: .secondary,
                                size: .large,
                                isEnabled: true
                            ) {
                                // Reset form
                                name = ""
                                email = ""
                                role = ""
                                presenter.resetForm()
                            },
                            
                            AppButton(
                                title: "Kembali ke Daftar Akun",
                                colorType: .tertiary,
                                isEnabled: true
                            ) {
                                presenter.resetForm()
                                presenter.navigateBack()
                            }
                        ],
                        isVisible: Binding(
                            get: { presenter.showSuccessPopup },
                            set: { newValue in
                                if !newValue {
                                    presenter.resetForm()
                                }
                            }
                        )
                    )
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        Image("AddAccount")
                        VStack(spacing: 16) {
                            AppDropdown(
                                title: "Role",
                                placeholder: "Laboran",
                                isRequired: true,
                                leftIcon: "person.fill",
                                rightIcon: "chevron.down",
                                isDisabled: false,
                                choices: [("Laboran", RolesType.LAB.rawValue), ("Admin", RolesType.ADMIN.rawValue)],
                                selectedChoice: $role
                            )
                        
                            AppTextField(
                                title: "Nama",
                                placeholder: "John Doe",
                                text: $name
                            )
                            
                            AppTextField(
                                title: "Email",
                                placeholder: "john@gmail.com",
                                text: $email
                            )
                            
                            if presenter.isRegistering {
                                ProgressView()
                            }
                            
                            AppButton(
                                title: "Daftarkan Akun",
                                rightIcon: "arrow.right",
                                isEnabled: presenter.isFormValid(name: name, email: email, role: role),
                                action: {
                                    registerAccount()
                                }
                            )
                        }
                        Spacer()
                    }
                    .padding(.horizontal, Decimal.d20)
                }
                .navigationTitle("Buat Akun Baru")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presenter.navigateBack()
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
        // Error alert
        .alert(
            "Registration Failed",
            isPresented: Binding(
                get: { presenter.registrationError != nil },
                set: { if !$0 { presenter.registrationError = nil } }
            ),
            actions: {
                Button("OK") {
                    presenter.registrationError = nil
                }
            },
            message: {
                Text(presenter.registrationError ?? "Unknown error")
            }
        )
    }
    
    // Move async task outside the view body
    private func registerAccount() {
        Task {
            await presenter.registerNewAccount(
                role: role,
                name: name,
                email: email
            )
        }
    }
}

#Preview {
    NewUserFormView()
}
