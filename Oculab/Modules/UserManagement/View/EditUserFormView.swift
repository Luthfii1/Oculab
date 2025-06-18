//
//  EditUserFormView.swift
//  Oculab
//
//  Created by Risa on 22/05/25.
//

import SwiftUI

struct EditUserFormView: View {
    @StateObject private var presenter = AccountPresenter()
    let account: Account
    
    var body: some View {
        NavigationView {
            ZStack {
                // Success popup
                if presenter.showSuccessPopup {
                    AppPopup(
                        image: "Success",
                        title: "Berhasil mengubah Akun",
                        description: "Anda telah berhasil mengubah akun untuk \(presenter.editSuccess.name) dengan role \(presenter.editSuccess.role)",
                        buttons: [
                            AppButton(
                                title: "Kembali ke Daftar Akun",
                                colorType: .secondary,
                                size: .large,
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
                                placeholder: presenter.role,
                                isRequired: true,
                                leftIcon: "person.fill",
                                rightIcon: "chevron.down",
                                choices: [("Laboran", RolesType.LAB.rawValue), ("Admin", RolesType.ADMIN.rawValue)],
                                isSearchEnabled: false,
                                selectedChoice: $presenter.role
                            )
                            
                            AppTextField(
                                title: "Nama",
                                isRequired: true,
                                placeholder: "Masukkan nama",
                                text: $presenter.name
                            )
                            
                            AppTextField(
                                title: "Email",
                                isRequired: true,
                                placeholder: "Email",
                                description: "Email tidak dapat diubah",
                                isDisabled: true,
                                text: .constant(account.email)
                            )

                            // Save button
                            ZStack {
                                AppButton(
                                    title: presenter.isEditing ? "" : "Simpan Perubahan",
                                    rightIcon: presenter.isEditing ? nil : "arrow.right",
                                    isEnabled: !presenter.isEditing,
                                    action: {
                                        Task {
                                            await presenter.editSelectedUser(
                                                role: presenter.role,
                                                name: presenter.name,
                                                userId: presenter.userId
                                            )
                                        }
                                    }
                                )
                                if presenter.isEditing {
                                    ProgressView()
                                        .tint(AppColors.slate200)
                                }
                            }
                            
                            Button("Batal") {
                                presenter.navigateBack()
                            }
                            .font(AppTypography.p2)
                            .foregroundColor(AppColors.slate600)
                            .padding(.top, 8)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, Decimal.d20)
                }
                .simultaneousGesture(
                    DragGesture().onChanged { _ in
                        UIApplication.shared.endEditing()
                    }
                )
                .navigationTitle("Edit Akun")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presenter.navigateBack()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.black)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .dismissKeyboardOnTap()
        // Error alert
        .alert(
            "Edit Failed",
            isPresented: Binding(
                get: { presenter.editError != nil },
                set: { if !$0 { presenter.editError = nil } }
            ),
            actions: {
                Button("OK") {
                    presenter.editError = nil
                }
            },
            message: {
                Text(presenter.editError ?? "Unknown error")
            }
        )
        .onAppear {
            presenter.setAccount(account: account)
        }
    }
}

#Preview {
    EditUserFormView(account:
                        Account(id: "xxxx", name: "ddd", role: RolesType.LAB, email: RolesType.LAB.rawValue, username: "ssSss.com", accessPin: "1111"))
}
