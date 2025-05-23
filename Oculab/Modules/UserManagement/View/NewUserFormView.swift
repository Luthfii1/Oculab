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
                        description: "Anda telah berhasil menambahkan akun baru untuk \(presenter.registrationSuccess.name) dengan role \(presenter.registrationSuccess.role)",
                        buttons: [
                            AppButton(
                                title: "Buat Akun Lain",
                                colorType: .secondary,
                                size: .large,
                                isEnabled: true
                            ) {
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
                            // Role dropdown
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
                            
                            // Name field
                            AppTextField(
                                title: "Nama",
                                isRequired: true,
                                placeholder: "John Doe",
                                text: $name
                            )
                            
                            // Email field
                            AppTextField(
                                title: "Email",
                                isRequired: true,
                                placeholder: "john@gmail.com",
                                text: $email
                            )
                            
                            // Loading indicator
                            if presenter.isRegistering {
                                ProgressView()
                            }
                            
                            // Register button
                            AppButton(
                                title: "Daftarkan Akun",
                                rightIcon: "arrow.right",
                                isEnabled: presenter.isFormValid(
                                    name: name,
                                    email: email,
                                    role: role
                                ),
                                action: {
                                    Task {
                                        await presenter.registerNewAccount(
                                            role: role,
                                            name: name,
                                            email: email
                                        )
                                    }
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
                                Image(systemName: "chevron.left")
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
}

#Preview {
    NewUserFormView()
}
