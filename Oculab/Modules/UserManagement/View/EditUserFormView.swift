//
//  EditUserFormView.swift
//  Oculab
//
//  Created by Risa on 22/05/25.
//

import SwiftUI

struct EditUserFormView: View {
    @EnvironmentObject var presenter: AccountPresenter
    let account: Account
    
    var body: some View {
        NavigationView {
            ZStack {
                // Success popup
                if presenter.showSuccessPopup {
                    AppPopup(
                        image: AppText.Icon.success,
                        title: AppTextUserMgmtEditUserForm.successTitle,
                        description: "\(AppTextUserMgmtEditUserForm.successDescriptionPrefix) \(presenter.editSuccess.name) \(AppTextUserMgmtEditUserForm.successDescriptionSuffix) \(presenter.editSuccess.role)",
                        buttons: [
                            AppButton(
                                title: AppTextUserMgmtEditUserForm.backToAccountListButton,
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
                        Image(AppText.Icon.addAccount)
                        VStack(spacing: 16) {
                            AppDropdown(
                                title: AppTextUserMgmtEditUserForm.roleTitle,
                                placeholder: presenter.role,
                                isRequired: true,
                                leftIcon: AppText.Icon.personFill,
                                rightIcon: AppText.Icon.chevronDown,
                                choices: [(AppTextUserMgmtNewUserForm.roleLabPlaceholder, RolesType.LAB.rawValue), (AppTextUserMgmtNewUserForm.roleAdminChoice, RolesType.ADMIN.rawValue)],
                                isSearchEnabled: false,
                                selectedChoice: $presenter.role
                            )
                            
                            AppTextField(
                                title: AppTextUserMgmtEditUserForm.nameTitle,
                                isRequired: true,
                                placeholder: AppTextUserMgmtEditUserForm.namePlaceholder,
                                text: $presenter.name
                            )
                            
                            AppTextField(
                                title: AppTextUserMgmtEditUserForm.emailTitle,
                                isRequired: true,
                                placeholder: AppTextUserMgmtEditUserForm.emailPlaceholder,
                                description: AppTextUserMgmtEditUserForm.emailDisabledDescription,
                                isDisabled: true,
                                text: .constant(account.email)
                            )

                            // Save button
                            ZStack {
                                AppButton(
                                    title: presenter.isEditing ? AppText.Common.emptyString : AppTextUserMgmtEditUserForm.saveChangesButton,
                                    rightIcon: presenter.isEditing ? nil : AppText.Icon.arrowRight,
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
                            
                            Button(AppTextUserMgmtEditUserForm.cancelButton) {
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
                .navigationTitle(AppTextUserMgmtEditUserForm.navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presenter.navigateBack()
                        }) {
                            Image(systemName: AppText.Icon.chevronLeft)
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
            AppTextUserMgmtEditUserForm.editFailedTitle,
            isPresented: Binding(
                get: { presenter.editError != nil },
                set: { if !$0 { presenter.editError = nil } }
            ),
            actions: {
                Button(AppText.Common.okButton) {
                    presenter.editError = nil
                }
            },
            message: {
                Text(presenter.editError ?? AppTextUserMgmtEditUserForm.unknownErrorMessage)
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
        .environmentObject(DependencyInjection.shared.createAccountPresenter())
}
