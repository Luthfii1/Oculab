//
//  AppTextUserManagement.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 02/08/25.
//

import Foundation

// MARK: UserManagement Module Texts
typealias AppTextUserMgmt = AppText.UserManagement
typealias AppTextUserMgmtView = AppText.UserManagement.UserManagementView
typealias AppTextUserMgmtNewUserForm = AppText.UserManagement.NewUserFormView
typealias AppTextUserMgmtEditUserForm = AppText.UserManagement.EditUserFormView
typealias AppTextUserMgmtUserListView = AppText.UserManagement.UserListView
typealias AppTextUserMgmtCompBottomSheet = AppText.UserManagement.BottomSheetMenuComponent

extension AppText {
    enum UserManagement {
        static let backToAccountList = AppAction.backTo("Daftar Akun")
        
        enum UserManagementView {
            static let deleteAccountTitle = "Hapus akun"
            static let deleteAccountDescription = "Akun yang sudah dihapus tidak dapat dikembalikan lagi."
            static let deleteSuccessDescription = "Akun berhasil dihapus"
            static let successDeleteAccount = AppState.success("Menghapus Akun")
            static let addNewAccount = AppAction.add("Akun Baru")
            static let failedDeleteAccount = AppState.failed("Menghapus")
            static let invalidEmailFormat = "Format email tidak valid"
            static let failedRegistration = "Failed to register account: No response from server"

            static func successDeleteAccount(_ name: String) -> String {
                return "\(name) telah berhasil dihapus."
            }
        }
        
        enum NewUserFormView {
            static let successDescriptionPrefix = "Anda telah berhasil menambahkan akun baru untuk"
            static let successDescriptionSuffix = "dengan role"
            static let roleLabPlaceholder = "Laboran"
            static let roleAdminChoice = "Admin"
            static let namePlaceholder = "Masukkan nama"
            static let emailPlaceholder = "Masukkan email"
            static let successCreateAccount = AppState.success("membuat Akun")
            static let createAnotherAccount = AppAction.create("Akun Lain")
            static let saveAccount = AppAction.save("Akun")
            static let navigationTitle = AppAction.create("Akun Baru")
            static let failedRegistration = AppState.failed("Pendaftaran")
        }
        
        enum EditUserFormView {
            static let successUpdateAccount = AppState.success("mengubah Akun")
            static let failedUpdateAccount = AppState.failed("Mengubah")
            static let navigationTitle = "Edit Akun"
            static let successDescriptionPrefix = "Anda telah berhasil mengubah akun untuk"
            static let successDescriptionSuffix = "dengan role"
            static let emailDisabledDescription = "Email tidak dapat diubah"
            static let namePlaceholder = "Masukkan nama"
            static let emailPlaceholder = "Masukkan email"
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
