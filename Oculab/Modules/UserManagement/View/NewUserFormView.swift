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
                        image: AppText.Icon.success,
                        title: AppTextUserMgmtNewUserForm.successTitle,
                        description: "\(AppTextUserMgmtNewUserForm.successDescriptionPrefix) \(presenter.registrationSuccess.name) \(AppTextUserMgmtNewUserForm.successDescriptionSuffix) \(presenter.registrationSuccess.role)",
                        buttons: [
                            AppButton(
                                title: AppTextUserMgmtNewUserForm.createAnotherAccountButton,
                                colorType: .secondary,
                                size: .large,
                                isEnabled: true
                            ) {
                                presenter.resetForm()
                            },
                            
                            AppButton(
                                title: AppTextUserMgmtNewUserForm.backToAccountListButton,
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
                        Image(AppText.Icon.addAccount)
                        VStack(spacing: 16) {
                            // Role dropdown
                            AppDropdown(
                                title: AppTextUserMgmtNewUserForm.roleTitle,
                                placeholder: AppTextUserMgmtNewUserForm.roleLabPlaceholder,
                                isRequired: true,
                                leftIcon: AppText.Icon.personFill,
                                rightIcon: AppText.Icon.chevronDown,
                                isDisabled: false,
                                choices: [(AppTextUserMgmtNewUserForm.roleLabPlaceholder, RolesType.LAB.rawValue), (AppTextUserMgmtNewUserForm.roleAdminChoice, RolesType.ADMIN.rawValue)],
                                isSearchEnabled: false,
                                selectedChoice: $presenter.role
                            )
                            
                            // Name field
                            AppTextField(
                                title: AppTextUserMgmtNewUserForm.nameTitle,
                                isRequired: true,
                                placeholder: AppTextUserMgmtNewUserForm.namePlaceholder,
                                text: $presenter.name
                            )
                            
                            // Email field
                            AppTextField(
                                title: AppTextUserMgmtNewUserForm.emailTitle,
                                isRequired: true,
                                placeholder: AppTextUserMgmtNewUserForm.emailPlaceholder,
                                description: presenter.editError,
                                isError: presenter.isError,
                                text: $presenter.email
                            )
                            
                            // Register button
                            ZStack {
                                AppButton(
                                    title: presenter.isRegistering ? AppText.Common.emptyString : AppTextUserMgmtNewUserForm.registerAccountButton,
                                    rightIcon: presenter.isRegistering ? nil : AppText.Icon.arrowRight,
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
                .navigationTitle(AppTextUserMgmtNewUserForm.navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presenter.navigateBack()
                        }) {
                            HStack {
                                Image(systemName: AppText.Icon.chevronLeft)
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
            AppTextUserMgmtNewUserForm.registrationFailedTitle,
            isPresented: Binding(
                get: { presenter.registrationError != nil },
                set: { if !$0 { presenter.registrationError = nil } }
            ),
            actions: {
                Button(AppText.Common.okButton) {
                    presenter.registrationError = nil
                }
            },
            message: {
                Text(presenter.registrationError ?? AppTextUserMgmtNewUserForm.unknownErrorMessage)
            }
        )
    }
}

#Preview {
    NewUserFormView()
        .environmentObject(DependencyInjection.shared.createAccountPresenter())
}
