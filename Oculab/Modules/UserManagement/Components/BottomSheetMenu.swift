//
//  BottomSheetMenu.swift
//  Oculab
//
//  Created by Risa on 11/05/25.
//

import SwiftUI

struct BottomSheetMenu: View {
    @ObservedObject var presenter: AccountPresenter
    @Environment(\.dismiss) private var dismiss
    @State private var isLoaded = false
    @State private var navigateToEdit = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !isLoaded {
                ProgressView()
                    .padding(.top, 32)
            }
            
            Text(presenter.selectedUser?.name ?? "")
                .font(AppTypography.s4)
                .foregroundColor(AppColors.slate900)
                .padding(.top, 32)
                .padding(.bottom, 4)
                .opacity(isLoaded ? 1 : 0)

            Button {
                // Find the full account for the selected user
                if let userId = presenter.selectedUser?.id,
                   let account = presenter.findAccountById(userId) {
                    print(userId)
                    presenter.navigateTo(.editAccount(account: account))
                    dismiss()
                }
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("Ubah Detail Akun")
                        .font(AppTypography.p3)
                }
                .foregroundColor(AppColors.slate900)
            }
            .padding(.vertical, 4)
            .opacity(isLoaded ? 1 : 0)

            Button {
                Task {
                    await presenter.deleteSelectedUser()
                    dismiss()
                }
            } label: {
                HStack {
                    if presenter.isDeleting {
                        ProgressView()
                            .foregroundColor(AppColors.red500)
                    } else {
                        Image(systemName: "trash")
                        Text("Hapus Akun")
                            .font(AppTypography.p3)
                    }
                }
                .foregroundColor(AppColors.red500)
            }
            .padding(.vertical, 4)
            .opacity(isLoaded ? 1 : 0)
            .disabled(presenter.isDeleting)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .presentationDetents([.fraction(0.2)])
        .presentationDragIndicator(.visible)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isLoaded = true
            }
        }
        .alert(
            presenter.deletionSuccess != nil ? "Deletion Successful" : "Deletion Failed",
            isPresented: Binding(
                get: { presenter.deletionSuccess != nil || presenter.deletionError != nil },
                set: {
                    if !$0 {
                        presenter.deletionSuccess = nil
                        presenter.deletionError = nil
                    }
                }
            ),
            actions: {
                Button("OK") {
                    presenter.deletionSuccess = nil
                    presenter.deletionError = nil
                }
            },
            message: {
                if let successInfo = presenter.deletionSuccess {
                    Text(successInfo.message)
                } else {
                    Text(presenter.deletionError ?? "Unknown error")
                }
            }
        )
    }
}

#Preview {
    BottomSheetMenu(presenter: AccountPresenter())
}
