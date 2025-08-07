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
            static let deleteAccountTitle = "Hapus akun"
            static let deleteAccountDescription = "Akun yang sudah dihapus tidak dapat dikembalikan lagi."
            static let deleteSuccessDescription = "Akun berhasil dihapus"
        }
        
        enum NewUserFormView {
            static let successDescriptionPrefix = "Anda telah berhasil menambahkan akun baru untuk"
            static let successDescriptionSuffix = "dengan role"
            static let roleLabPlaceholder = "Laboran"
            static let roleAdminChoice = "Admin"
            static let namePlaceholder = "Masukkan nama"
            static let emailPlaceholder = "Masukkan email"
        }
        
        enum EditUserFormView {
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
