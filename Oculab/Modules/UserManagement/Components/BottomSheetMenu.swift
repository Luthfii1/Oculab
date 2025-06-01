////
////  BottomSheetMenu.swift
////  Oculab
////
////  Created by Risa on 11/05/25.
////
//
//import SwiftUI
//
//struct BottomSheetMenu: View {
//    @ObservedObject var presenter: AccountPresenter
//    @Environment(\.dismiss) private var dismiss
//    @State private var isLoaded = false
//    @State private var navigateToEdit = false
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            if !isLoaded {
//                ProgressView()
//                    .padding(.top, 32)
//            }
//            
//            Text(presenter.selectedUser?.name ?? "")
//                .font(AppTypography.s4)
//                .foregroundColor(AppColors.slate900)
//                .padding(.top, 32)
//                .padding(.bottom, 4)
//                .opacity(isLoaded ? 1 : 0)
//
//            Button {
//                // Find the full account for the selected user
//                if let userId = presenter.selectedUser?.id,
//                   let account = presenter.findAccountById(userId) {
//                    presenter.navigateTo(.editAccount(account: account))
//                    dismiss()
//                }
//            } label: {
//                HStack {
//                    Image(systemName: "pencil")
//                    Text("Ubah Detail Akun")
//                        .font(AppTypography.p3)
//                }
//                .foregroundColor(AppColors.slate900)
//            }
//            .padding(.vertical, 4)
//            .opacity(isLoaded ? 1 : 0)
//
//            Button {
////                Task {
//                    AppPopup(
//                        image: "Confirm",
//                        title: "Hapus Akun \(presenter.selectedUser?.name ?? "")?",
//                        description: "Akun yang sudah dihapus tidak dapat diubah kembali",
//                        buttons: [
//                            AppButton(
//                                title: "Kembali ke Manajemen Akun",
//                                colorType: .secondary,
//                                size: .large,
//                                isEnabled: true
//                            ) {
//                                dismiss()
//                            },
//                            
//                            AppButton(
//                                title: "Hapus Akun",
//                                colorType: .tertiary,
//                                isEnabled: true
//                            ) {
//                                Task {
//                                    await presenter.deleteSelectedUser()
//                                }
//                            }
//                        ],
//                        isVisible: Binding(
//                            get: { presenter.showSuccessPopup },
//                            set: { newValue in
//                                if !newValue {
//                                    presenter.resetForm()
//                                }
//                            }
//                        )
//                    )
////                    await presenter.deleteSelectedUser()
////                    dismiss()
////                }
//            } label: {
//                HStack {
//                    if presenter.isDeleting {
//                        ProgressView()
//                            .foregroundColor(AppColors.red500)
//                    } else {
//                        Image(systemName: "trash")
//                        Text("Hapus Akun")
//                            .font(AppTypography.p3)
//                    }
//                }
//                .foregroundColor(AppColors.red500)
//            }
//            .padding(.vertical, 4)
//            .opacity(isLoaded ? 1 : 0)
//            .disabled(presenter.isDeleting)
//
//            Spacer()
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding()
//        .presentationDetents([.fraction(0.2)])
//        .presentationDragIndicator(.visible)
//        .onAppear {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                isLoaded = true
//            }
//        }
//        .alert(
//            presenter.deletionSuccess != nil ? "Deletion Successful" : "Deletion Failed",
//            isPresented: Binding(
//                get: { presenter.deletionSuccess != nil || presenter.deletionError != nil },
//                set: {
//                    if !$0 {
//                        presenter.deletionSuccess = nil
//                        presenter.deletionError = nil
//                    }
//                }
//            ),
//            actions: {
//                Button("OK") {
//                    presenter.deletionSuccess = nil
//                    presenter.deletionError = nil
//                }
//            },
//            message: {
//                if let successInfo = presenter.deletionSuccess {
//                    Text(successInfo.message)
//                } else {
//                    Text(presenter.deletionError ?? "Unknown error")
//                }
//            }
//        )
//    }
//}
//
//#Preview {
//    BottomSheetMenu(presenter: AccountPresenter())
//}
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
    @State private var showDeletePopup = false

    var body: some View {
        ZStack {
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
                    showDeletePopup = true
                } label: {
                    HStack {
                        if presenter.isDeleting {
                            ProgressView()
                                .scaleEffect(0.8)
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
            
            // AppPopup overlay
            if showDeletePopup {
                AppPopup(
                    image: "Confirm",
                    title: "Hapus Akun \(presenter.selectedUser?.name ?? "")?",
                    description: "Akun akan terhapus secara permanen",
                    buttons: [
                        AppButton(
                            title: "Kembali ke Manajemen Akun",
                            colorType: .secondary,
                            size: .large,
                            isEnabled: true
                        ) {
                            showDeletePopup = false
                        },
                        
                        AppButton(
                            title: "Hapus Akun",
                            colorType: .tertiary,
                            isEnabled: !presenter.isDeleting
                        ) {
                            Task {
                                await presenter.deleteSelectedUser()
                                showDeletePopup = false
                            }
                        }
                    ],
                    isVisible: $showDeletePopup
                )
            }
        }
        .presentationDetents([.fraction(0.2)])
        .presentationDragIndicator(.visible)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoaded = true
                }
            }
        }
        .alert(
            presenter.deletionSuccess != nil ? "Deletion Successful" : "Deletion Failed",
            isPresented: Binding(
                get: { presenter.deletionSuccess != nil || presenter.deletionError != nil },
                set: { _ in
                    presenter.deletionSuccess = nil
                    presenter.deletionError = nil
                }
            ),
            actions: {
                Button("OK") {
                    presenter.deletionSuccess = nil
                    presenter.deletionError = nil
                    dismiss()
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
