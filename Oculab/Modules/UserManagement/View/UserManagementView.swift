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
                        searchText: .constant(""),
                        onSearch: {}
                    )

                    AppButton(
                        title: "Tambah Akun Baru",
                        leftIcon: "plus",
                        colorType: .secondary,
                        action: {
                            presenter.navigateTo(.newAccount)
                        }
                    )

                    VStack(spacing: 24) {
                        UserListView(presenter: presenter)
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
            .sheet(item: $presenter.selectedUser) { _ in
                BottomSheetMenu(presenter: presenter)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    UserManagementView()
}
