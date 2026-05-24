//
//  EditUserFormView.swift
//  Oculab
//
//  Created by Risa on 22/05/25.
//

import SwiftUI

struct EditUserFormView: View {
    @EnvironmentObject private var presenter: AccountPresenter
    let account: Account
    
    var body: some View {
        NavigationView {
            ZStack {
                // Success popup
                if presenter.showSuccessPopup {
                    AppPopup(
                        image: AppImage.success,
                        title: AppTextUserMgmtEditUserForm.successUpdateAccount,
                        description: AppData.makeSentence([AppTextUserMgmtEditUserForm.successDescriptionPrefix, presenter.editSuccess.name, AppTextUserMgmtEditUserForm.successDescriptionSuffix, presenter.editSuccess.role]),
                        buttons: [
                            AppButton(
                                title: AppTextUserMgmt.backToAccountList,
                                colorType: .secondary,
                                size: .large,
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
                            AppDropdown(
                                title: AppLabel.role,
                                placeholder: presenter.role,
                                isRequired: true,
                                leftIcon: AppIcon.personFill,
                                rightIcon: AppIcon.down,
                                choices: [(AppTextUserMgmtNewUserForm.roleLabPlaceholder, RolesType.LAB.rawValue), (AppTextUserMgmtNewUserForm.roleAdminChoice, RolesType.ADMIN.rawValue)],
                                isSearchEnabled: false,
                                selectedChoice: $presenter.role
                            )
                            
                            ValidatedTextField(
                                title: AppLabel.name,
                                isRequired: true,
                                placeholder: AppTextUserMgmtEditUserForm.namePlaceholder,
                                text: $presenter.name,
                                fieldName: .userName
                            )
                            
                            ValidatedTextField(
                                title: AppLabel.email,
                                isRequired: true,
                                placeholder: AppTextUserMgmtEditUserForm.emailPlaceholder,
                                isDisabled: true,
                                text: .constant(account.email),
                                fieldName: .userEmail
                            )

                            // Save button
                            ZStack {
                                AppButton(
                                    title: presenter.isEditing ? AppValue.empty : AppAction.saveChanges,
                                    rightIcon: presenter.isEditing ? nil : AppIcon.forward,
                                    isEnabled: presenter.isFormValid,
                                    action: {
                                        Task {
                                            await presenter.editSelectedUserWithValidation(
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
                            
                            Button(AppAction.cancel) {
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
                            Image(systemName: AppIcon.back)
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
            AppTextUserMgmtEditUserForm.failedUpdateAccount,
            isPresented: Binding(
                get: { presenter.editError != nil },
                set: { if !$0 { presenter.editError = nil } }
            ),
            actions: {
                Button(AppAction.ok) {
                    presenter.editError = nil
                }
            },
            message: {
                Text(presenter.editError ?? AppValue.unknownError)
            }
        )
        .onAppear {
            presenter.setAccount(account: account)
        }
        .onDisappear {
            presenter.resetForm()
        }
    }
}

//#Preview {
//    EditUserFormView(account:
//                        Account(id: "xxxx", name: "ddd", role: RolesType.LAB, email: RolesType.LAB.rawValue, username: "ssSss.com", accessPin: "1111"))
//        .environmentObject(DependencyInjection.shared.createAccountPresenter())
//}
