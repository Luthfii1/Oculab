//
//  AppTextUserManagement.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 02/08/25.
//

import Foundation

// MARK: UserManagement Module Texts
typealias AppTextUserMgmtView = AppText.UserManagement.UserManagementView
typealias AppTextUserMgmtNewUserForm = AppText.UserManagement.NewUserFormView
typealias AppTextUserMgmtEditUserForm = AppText.UserManagement.EditUserFormView
typealias AppTextUserMgmtUserListView = AppText.UserManagement.UserListView
typealias AppTextUserMgmtCompBottomSheet = AppText.UserManagement.BottomSheetMenuComponent

extension AppText {
    enum UserManagement {
        enum UserManagementView {
            static let addNewAccountButton = AppAction.add("Akun Baru")
            static let deleteAccountTitle = "Hapus akun"
            static let deleteAccountDescription = "Akun yang sudah dihapus tidak dapat dikembalikan lagi."
            static let deleteAccountButton = AppAction.delete("Akun")
            static let deleteSuccessTitle = AppState.success("Menghapus Akun")
            static let deleteSuccessDescription = "Akun berhasil dihapus"
            static let deletionFailedTitle = AppState.failed("Menghapus")
        }
        
        enum NewUserFormView {
            static let navigationTitle = AppAction.create("Akun Baru")
            static let successTitle = AppState.success("membuat Akun")
            static let successDescriptionPrefix = "Anda telah berhasil menambahkan akun baru untuk"
            static let successDescriptionSuffix = "dengan role"
            static let createAnotherAccountButton = AppAction.create("Akun Lain")
            static let backToAccountListButton = AppAction.backTo("Daftar Akun")
            static let roleLabPlaceholder = "Laboran"
            static let roleAdminChoice = "Admin"
            static let registerAccountButton = AppAction.save("Akun")
            static let registrationFailedTitle = AppState.failed("Pendaftaran")
        }
        
        enum EditUserFormView {
            static let navigationTitle = "Edit Akun"
            static let successTitle = AppState.success("mengubah Akun")
            static let successDescriptionPrefix = "Anda telah berhasil mengubah akun untuk"
            static let successDescriptionSuffix = "dengan role"
            static let backToAccountListButton = AppAction.backTo("Daftar Akun")
            static let emailDisabledDescription = "Email tidak dapat diubah"
            static let editFailedTitle = AppState.failed("Mengubah")
        }
        
        enum UserListView {
            // This component doesn't have specific hardcoded strings, but keeping for consistency
        }
        
        enum BottomSheetMenuComponent {
            static let editAccountDetailsButton = "Ubah Detail Akun"
            static let deleteAccountButton = "Hapus Akun"
        }
    }
}