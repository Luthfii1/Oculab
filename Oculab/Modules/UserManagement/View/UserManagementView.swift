//
//  UserManagementView.swift
//  Oculab
//
//  Created by Risa on 07/05/25.
//

import SwiftUI

struct UserManagementView: View {
    @EnvironmentObject var presenter: AccountPresenter
    
    var body: some View {
        NavigationView {
            ZStack {
                // Delete confirmation popup
                if presenter.showDeleteConfirmationPopup {
                    AppPopup(
                        image: AppImage.confirm,
                        title: "\(AppTextUserMgmtView.deleteAccountTitle) \(presenter.userToDelete?.name ?? AppValue.empty)?",
                        description: AppTextUserMgmtView.deleteAccountDescription,
                        buttons: [
                            AppButton(
                                title: AppTextUserMgmtView.deleteAccountButton,
                                colorType: .destructive(.primary),
                                isEnabled: !presenter.isDeleting
                            ) {
                                Task {
                                    await presenter.confirmDeleteSelectedUser()
                                }
                            },
                            AppButton(
                                title: AppTextUserMgmtView.backButton,
                                colorType: .destructive(.secondary)
                            ) {
                                presenter.dismissDeleteConfirmation()
                            }
                        ],
                        isVisible: $presenter.showDeleteConfirmationPopup
                    )
                }
                
                // Delete success popup
                if presenter.showDeleteSuccessAlert {
                    AppPopup(
                        image: AppImage.success,
                        title: AppTextUserMgmtView.deleteSuccessTitle,
                        description: presenter.deletionSuccess?.message ?? AppTextUserMgmtView.deleteSuccessDescription,
                        buttons: [
                            AppButton(
                                title: AppText.Common.okButton,
                                colorType: .primary,
                                size: .large,
                                isEnabled: true
                            ) {
                                presenter.dismissDeleteAlert()
                            }
                        ],
                        isVisible: $presenter.showDeleteSuccessAlert
                    )
                }
                
                ScrollView {
                    Spacer().frame(height: Decimal.d24)

                    VStack(spacing: 24) {
                        AppSearchBar(
                            searchText: $presenter.searchText,
                            placeholder: AppTextUserMgmtView.searchPlaceholder,
                            onSearch: {
                                presenter.searchAccounts(query: presenter.searchText)
                            }
                        )

                        AppButton(
                            title: AppTextUserMgmtView.addNewAccountButton,
                            leftIcon: AppText.Icon.plus,
                            colorType: .secondary,
                            action: {
                                presenter.navigateTo(.newAccount)
                            }
                        )
                        
                        if !presenter.searchText.isEmpty && presenter.displayedSortedGroupedAccounts.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: AppIcon.magnifyingglass)
                                    .font(.system(size: 48))
                                    .foregroundColor(AppColors.slate300)
                                
                                Text("\(AppTextUserMgmtView.noResultsPrefix) \"\(presenter.searchText)\"")
                                    .font(AppTypography.s3)
                                    .foregroundColor(AppColors.slate600)
                                    .multilineTextAlignment(.center)
                                
                                Button(action: {
                                    presenter.clearSearch()
                                }) {
                                    Text(AppTextUserMgmtView.clearSearchButton)
                                        .font(AppTypography.p2)
                                        .foregroundColor(AppColors.purple600)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            if presenter.isUserLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                            } else {
                                VStack(spacing: 24) {
                                    UserListView()
                                        .environmentObject(presenter)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Decimal.d20)
                    .navigationTitle(AppTextUserMgmtView.navigationTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                presenter.navigateBack()
                            }) {
                                Image(AppText.Icon.back)
                            }
                        }
                    }
                }
                .dismissKeyboardOnTap()
                .sheet(item: $presenter.selectedUser) { _ in
                    BottomSheetMenu(presenter: presenter)
                }
                .alert(
                    AppTextUserMgmtView.deletionFailedTitle,
                    isPresented: Binding(
                        get: { presenter.deletionError != nil },
                        set: { if !$0 { presenter.deletionError = nil } }
                    ),
                    actions: {
                        Button(AppText.Common.okButton) {
                            presenter.deletionError = nil
                        }
                    },
                    message: {
                        Text(presenter.deletionError ?? AppTextUserMgmtView.unknownErrorMessage)
                    }
                )
                .onAppear {
                    Task {
                        await presenter.fetchAllAccount()
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    UserManagementView()
        .environmentObject(DependencyInjection.shared.createAccountPresenter())
}
