//
//  UserManagementView.swift
//  Oculab
//
//  Created by Risa on 07/05/25.
//

import SwiftUI

struct UserManagementView: View {
    @StateObject private var presenter = AccountPresenter()
    
    var body: some View {
        NavigationView {
            ScrollView {
                Spacer().frame(height: Decimal.d24)

                VStack(spacing: 24) {
                    AppSearchBar(
                        searchText: $presenter.searchText,
                        placeholder: "Cari akun",
                        onSearch: {
                            presenter.searchAccounts(query: presenter.searchText)
                        }
                    )

                    AppButton(
                        title: "Tambah Akun Baru",
                        leftIcon: "plus",
                        colorType: .secondary,
                        action: {
                            presenter.navigateTo(.newAccount)
                        }
                    )
                    
                    if !presenter.searchText.isEmpty && presenter.displayedSortedGroupedAccounts.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.slate300)
                            
                            Text("Tidak ada hasil untuk \"\(presenter.searchText)\"")
                                .font(AppTypography.s3)
                                .foregroundColor(AppColors.slate600)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                presenter.clearSearch()
                            }) {
                                Text("Hapus Pencarian")
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
                .navigationTitle("Manajemen Akun")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presenter.navigateBack()
                        }) {
                            Image("back")
                        }
                    }
                }
            }
            .simultaneousGesture(
                DragGesture().onChanged { _ in
                    UIApplication.shared.endEditing()
                }
            )
            .sheet(item: $presenter.selectedUser) { _ in
                BottomSheetMenu(presenter: presenter)
            }
            .onAppear {
                Task {
                    await presenter.fetchAllAccount()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    UserManagementView()
}
