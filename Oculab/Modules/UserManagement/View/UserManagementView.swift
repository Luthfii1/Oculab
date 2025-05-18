//
//  UserManagementView.swift
//  Oculab
//
//  Created by Risa on 07/05/25.
//

import SwiftUI

struct UserManagementView: View {
    @ObservedObject private var presenter = AccountPresenter()
//    @EnvironmentObject private var authentication: AuthenticationPresenter
    @State private var selectedUser: String? = nil
    @State private var showSheet = false

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
                        UserListView { name in
                            selectedUser = name
                            showSheet = true
                        }
                    }
                }
                .padding(.horizontal, Decimal.d20)
                .navigationTitle("Manajemen Akun")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            Router.shared.navigateBack()
                        }) {
                            Image("back")
                        }
                    }
                }
            }
            .sheet(isPresented: Binding<Bool>(
                get: { selectedUser != nil && showSheet },
                set: { if !$0 { showSheet = false; selectedUser = nil } }
            )) {
                if let name = selectedUser {
                    BottomSheetMenu(userName: name)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    UserManagementView()
}
