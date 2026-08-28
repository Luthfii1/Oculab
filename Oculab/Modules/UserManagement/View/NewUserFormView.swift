//
//  NewUserFormView.swift
//  Oculab
//
//  Created by Risa on 07/05/25.
//

import SwiftUI

struct NewUserFormView: View {
    @EnvironmentObject private var presenter: AccountPresenter

    var body: some View {
        NavigationView {
            ZStack {
                // Success popup
                if presenter.showSuccessPopup {
                    AppPopup(
                        image: AppImage.success,
                        title: AppTextUserMgmtNewUserForm.successCreateAccount,
                        description: {
                            let base = AppData.makeSentence([
                                AppTextUserMgmtNewUserForm.successDescriptionPrefix,
                                presenter.registrationSuccess.name,
                                AppTextUserMgmtNewUserForm.successDescriptionSuffix,
                                presenter.registrationSuccess.role
                            ])
                            guard presenter.registrationSuccess.inviteEmailed else { return base }
                            return "\(base). \(AppTextUserMgmtNewUserForm.successInviteEmailed)"
                        }(),
                        buttons: [
                            AppButton(
                                title: AppTextUserMgmtNewUserForm.createAnotherAccount,
                                colorType: .secondary,
                                size: .large,
                                isEnabled: true,
                                action: {
                                    presenter.resetForm()
                                }
                            ),
                            
                            AppButton(
                                title: AppTextUserMgmt.backToAccountList,
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
                            ValidatedTextField(
                                title: AppLabel.name,
                                isRequired: true,
                                placeholder: AppTextUserMgmtNewUserForm.namePlaceholder,
                                text: $presenter.name,
                                fieldName: .userName
                            )
                            
                            // Email field
                            ValidatedTextField(
                                title: AppLabel.email,
                                isRequired: true,
                                placeholder: AppTextUserMgmtNewUserForm.emailPlaceholder,
                                text: $presenter.email,
                                fieldName: .userEmail
                            )
                            
                            // Register button
                            ZStack {
                                AppButton(
                                    title: presenter.isRegistering ? AppValue.empty : AppTextUserMgmtNewUserForm.saveAccount,
                                    rightIcon: presenter.isRegistering ? nil : AppIcon.forward,
                                    isEnabled: presenter.isFormValid,
                                    action: {
                                        Task {
                                            await presenter.registerNewAccountWithValidation(
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
            AppTextUserMgmtNewUserForm.failedRegistration,
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
        .onDisappear {
            presenter.resetForm()
        }
    }
}

#Preview {
    NewUserFormView()
        .environmentObject(DependencyInjection.shared.createAccountPresenter())
}
