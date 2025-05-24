//
//  NewUserFormView.swift
//  Oculab
//
//  Created by Risa on 07/05/25.
//

import SwiftUI

struct NewUserFormView: View {
    @StateObject private var presenter = AccountPresenter()
    
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
                                isSearchEnabled: false,
                                selectedChoice: $presenter.role
                            )
                            
                            // Name field
                            AppTextField(
                                title: "Nama",
                                isRequired: true,
                                placeholder: "John Doe",
                                text: $presenter.name
                            )
                            
                            // Email field
                            AppTextField(
                                title: "Email",
                                isRequired: true,
                                placeholder: "john@gmail.com",
                                description: presenter.editError,
                                isError: presenter.isError,
                                text: $presenter.email
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
                                    name: presenter.name,
                                    email: presenter.email,
                                    role: presenter.role
                                ),
                                action: {
                                    Task {
                                        await presenter.registerNewAccount(
                                            role: presenter.role,
                                            name: presenter.name,
                                            email: presenter.email
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
        .dismissKeyboardOnTap()
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
