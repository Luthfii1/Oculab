//
//  NewUserFormView.swift
//  Oculab
//
//  Created by Risa on 07/05/25.
//

import SwiftUI

struct NewUserFormView: View {
    @EnvironmentObject var presenter: AccountPresenter

    var body: some View {
        NavigationView {
            ZStack {
                // Success popup
                if presenter.showSuccessPopup {
                    AppPopup(
                        image: AppImage.success,
                        title: AppState.success("membuat Akun"),
                        description: "\(AppTextUserMgmtNewUserForm.successDescriptionPrefix) \(presenter.registrationSuccess.name) \(AppTextUserMgmtNewUserForm.successDescriptionSuffix) \(presenter.registrationSuccess.role)",
                        buttons: [
                            AppButton(
                                title: AppAction.create("Akun Lain"),
                                colorType: .secondary,
                                size: .large,
                                isEnabled: true,
                                action: {
                                    presenter.resetForm()
                                }
                            ),
                            
                            AppButton(
                                title: AppAction.backTo("Daftar Akun"),
                                colorType: .tertiary,
                                isEnabled: true,
                                action: {
                                    presenter.resetForm()
                                    presenter.navigateBack()
                                }
                            )
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
                        Image(AppImage.addAccount)
                        VStack(spacing: 16) {
                            // Role dropdown
                            AppDropdown(
                                title: AppLabel.role,
                                placeholder: AppTextUserMgmtNewUserForm.roleLabPlaceholder,
                                isRequired: true,
                                leftIcon: AppIcon.personFill,
                                rightIcon: AppIcon.down,
                                isDisabled: false,
                                choices: [(AppTextUserMgmtNewUserForm.roleLabPlaceholder, RolesType.LAB.rawValue), (AppTextUserMgmtNewUserForm.roleAdminChoice, RolesType.ADMIN.rawValue)],
                                isSearchEnabled: false,
                                selectedChoice: $presenter.role
                            )
                            
                            // Name field
                            AppTextField(
                                title: AppLabel.name,
                                isRequired: true,
                                placeholder: AppTextUserMgmtNewUserForm.namePlaceholder,
                                text: $presenter.name
                            )
                            
                            // Email field
                            AppTextField(
                                title: AppLabel.email,
                                isRequired: true,
                                placeholder: AppTextUserMgmtNewUserForm.emailPlaceholder,
                                description: presenter.editError,
                                isError: presenter.isError,
                                text: $presenter.email
                            )
                            
                            // Register button
                            ZStack {
                                AppButton(
                                    title: presenter.isRegistering ? AppValue.empty : AppAction.save("Akun"),
                                    rightIcon: presenter.isRegistering ? nil : AppIcon.forward,
                                    isEnabled: presenter.isFormValid(
                                        name: presenter.name,
                                        email: presenter.email,
                                        role: presenter.role
                                    ) && !presenter.isRegistering,
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
                                if presenter.isRegistering {
                                    ProgressView()
                                        .tint(AppColors.slate200)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, Decimal.d20)
                }
                .navigationTitle(AppAction.create("Akun Baru"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presenter.navigateBack()
                        }) {
                            HStack {
                                Image(systemName: AppIcon.back)
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
            AppState.failed("Pendaftaran"),
            isPresented: Binding(
                get: { presenter.registrationError != nil },
                set: { if !$0 { presenter.registrationError = nil } }
            ),
            actions: {
                Button(AppAction.ok) {
                    presenter.registrationError = nil
                }
            },
            message: {
                Text(presenter.registrationError ?? AppValue.unknownError)
            }
        )
    }
}

#Preview {
    NewUserFormView()
        .environmentObject(DependencyInjection.shared.createAccountPresenter())
}
