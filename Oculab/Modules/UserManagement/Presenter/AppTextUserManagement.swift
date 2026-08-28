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
        static let backToAccountList = AppAction.backTo("user_management.back_to_account_list_data".localized)
        
        enum UserManagementView {
            static let deleteAccountTitle = "user_management.view.delete_account_title".localized
            static let deleteAccountDescription = "user_management.view.delete_account_description".localized
            static let deleteSuccessDescription = "user_management.view.delete_success_description".localized
            static let successDeleteAccount = AppState.success("user_management.view.success_delete_account_action".localized)
            static let addNewAccount = AppAction.add("user_management.view.add_new_account_data".localized)
            static let failedDeleteAccount = AppState.failed("user_management.view.failed_delete_account_action".localized)
            static let invalidEmailFormat = "user_management.view.invalid_email_format".localized
            static let failedRegistration = "user_management.view.failed_registration".localized

            static func successDeleteAccount(_ name: String) -> String {
                return "user_management.view.success_delete_account_name".localized(with: [name])
            }
        }
        
        enum NewUserFormView {
            static let successDescriptionPrefix = "user_management.new_user_form.success_description_prefix".localized
            static let successDescriptionSuffix = "user_management.new_user_form.success_description_suffix".localized
            static let successInviteEmailed = "user_management.new_user_form.success_invite_emailed".localized
            static let roleLabPlaceholder = "user_management.new_user_form.role_lab_placeholder".localized
            static let roleAdminChoice = "user_management.new_user_form.role_admin_choice".localized
            static let namePlaceholder = "user_management.new_user_form.name_placeholder".localized
            static let emailPlaceholder = "user_management.new_user_form.email_placeholder".localized
            static let successCreateAccount = AppState.success("user_management.new_user_form.success_create_account_action".localized)
            static let createAnotherAccount = AppAction.create("user_management.new_user_form.create_another_account_data".localized)
            static let saveAccount = AppAction.save("user_management.new_user_form.save_account_data".localized)
            static let navigationTitle = AppAction.create("user_management.new_user_form.navigation_title_data".localized)
            static let failedRegistration = AppState.failed("user_management.new_user_form.failed_registration_action".localized)
        }
        
        enum EditUserFormView {
            static let successUpdateAccount = AppState.success("user_management.edit_user_form.success_update_account_action".localized)
            static let failedUpdateAccount = AppState.failed("user_management.edit_user_form.failed_update_account_action".localized)
            static let navigationTitle = "user_management.edit_user_form.navigation_title".localized
            static let successDescriptionPrefix = "user_management.edit_user_form.success_description_prefix".localized
            static let successDescriptionSuffix = "user_management.edit_user_form.success_description_suffix".localized
            static let emailDisabledDescription = "user_management.edit_user_form.email_disabled_description".localized
            static let namePlaceholder = "user_management.edit_user_form.name_placeholder".localized
            static let emailPlaceholder = "user_management.edit_user_form.email_placeholder".localized
        }
        
        enum UserListView {
            // This component doesn't have specific hardcoded strings, but keeping for consistency
        }
        
        enum BottomSheetMenuComponent {
            static let editAccountDetailsButton = "user_management.bottom_sheet.edit_account_details_button".localized
            static let deleteAccountButton = "user_management.bottom_sheet.delete_account_button".localized
        }
    }
}
