//
//  AccountManagementView.swift
//  Oculab
//
//  Created by Risa on 07/05/25.
//

import SwiftUI

struct AccountManagementView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                
                AppButton(
                    title: "Tambah Akun Baru",
                    leftIcon: "plus",
                    colorType: .secondary,
                    action: {}
                )
                VStack(spacing: 16) {

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
                        HStack {
                            Image("back")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    AccountManagementView()
}
