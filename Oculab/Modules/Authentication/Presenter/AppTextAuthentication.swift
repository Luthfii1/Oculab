//
//  AppTextAuthentication.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 02/08/25.
//

import Foundation

// MARK: Authentication Module Texts
typealias AppTextAuthLogin = AppText.Authentication.LoginView
typealias AppTextAuthEditPassword = AppText.Authentication.EditPasswordView
typealias AppTextAuthUserAccessPin = AppText.Authentication.UserAccessPinView
typealias AppTextAuthProfile = AppText.Authentication.ProfileView
typealias AppTextAuthPrivacyPolicy = AppText.Authentication.PrivacyPolicyView
typealias AppTextAuthCompPin = AppText.Authentication.PinComponent
typealias AppTextAuthBiometric = AppText.Authentication.Biometric
typealias AppTextAuthRegister = AppText.Authentication.RegisterView

extension AppText {
    enum Authentication {
        enum RegisterView {
            static let navigationTitle = "register.navigation_title".localized
            static let fullNameTitle = "register.full_name.title".localized
            static let fullNamePlaceholder = "register.full_name.placeholder".localized
            static let emailTitle = "register.email.title".localized
            static let emailPlaceholder = "register.email.placeholder".localized
            static let healthFacilityNameTitle = "register.health_facility_name.title".localized
            static let healthFacilityNamePlaceholder = "register.health_facility_name.placeholder".localized
            static let healthFacilityTypeTitle = "register.health_facility_type.title".localized
            static let healthFacilityTypePlaceholder = "register.health_facility_type.placeholder".localized
            static let submitButton = "register.submit_button".localized
            static let alreadyHaveAccount = "register.already_have_account".localized
            static let loginHere = "register.login_here".localized
            static let registerFailedText = "auth.register.failed".localized
            static let successRegisterMessage = "register.success_message".localized
            static let validationErrorFillAllFields = "register.validation_error_fill_all_fields".localized

            // Registration Entry (B2B/B2C)
            static let entryNavigationTitle = "register.entry.navigation_title".localized
            static let entryTitle = "register.entry.title".localized
            static let entryHealthFacilityButton = "register.entry.health_facility_button".localized
            static let entryHealthFacilityDescription = "register.entry.health_facility_description".localized
            static let entryIndividualButton = "register.entry.individual_button".localized
            static let entryIndividualDescription = "register.entry.individual_description".localized
        }

        enum Biometric {
            static let prompt = "auth.biometric.prompt".localized
            static let activationPrompt = "auth.biometric.activation_prompt".localized
            static let activateBiometricTitle = "auth.biometric.activate_title".localized
            static let activateBiometricDescription = "auth.biometric.activate_description".localized
            static let activateBiometricEnableButtonText = "auth.biometric.activate_enable_button".localized
            static let activateBiometricCancelButtonText = "auth.biometric.activate_cancel_button".localized
        }
        
        enum LoginView {
            static let title = "auth.login.title".localized
            static let emailPlaceholder = "auth.login.email.placeholder".localized
            static let passwordPlaceholder = "auth.login.password.placeholder".localized
            static let buttonText = "auth.login.button".localized
            static let faskesNotRegisteredYet = "auth.login.not_registered".localized
            static let registerFaskesButtonText = "auth.login.register_facility".localized
            static let loginFailedText = "auth.login.failed".localized
            static let dontHaveAccount = "auth.login.dont_have_account".localized
            static let registerAccountButtonText = "auth.login.register_account_button".localized
        }
        
        enum EditPasswordView {
            static let successUpdatePasswordTitle = "auth.edit_password.success_title".localized
            static let successUpdatePasswordMessage = "auth.edit_password.success_message".localized
            static let successUpdatePasswordButtonText = "auth.edit_password.success_button".localized
            static let navigationTitle = "auth.edit_password.navigation_title".localized
            static let currentPasswordTitle = "auth.edit_password.current_password_title".localized
            static let currentPasswordPlaceholder = AppForm.placeholder("auth.edit_password.current_password".localized)
            static let newPasswordTitle = "auth.edit_password.new_password_title".localized
            static let newPasswordPlaceholder = AppForm.placeholder("auth.edit_password.new_password".localized)
            static let newPasswordDescription = "auth.edit_password.new_password_description".localized
            static let confirmPasswordTitle = "auth.edit_password.confirm_password_title".localized
            static let confirmPasswordPlaceholder = AppForm.placeholder("auth.edit_password.confirm_password".localized)
        }

        enum UserAccessPinView {
            static let successTitle = "auth.pin.success_title".localized
            static let successDescription = "auth.pin.success_description".localized
            static let successButton = "auth.pin.success_button".localized
        }

        enum ProfileView {
            static let accountInfoTitle = "auth.profile.account_info".localized
            static let jobTitleKey = "auth.profile.job_title".localized
            static let jobTitleValue = "auth.profile.job_title_value".localized
            static let healthFacilityKey = "auth.profile.health_facility".localized
            static let editPasswordButton = "auth.profile.edit_password".localized
            static let editPinButton = "auth.profile.edit_pin".localized
            static let faceIdToggle = "auth.profile.face_id".localized
            static let privacyPolicyButton = "auth.profile.privacy_policy".localized

            static let descFaceIdNotEnabled = "auth.profile.face_id_not_enabled".localized
            static let descFaceIdNotSupported = "auth.profile.face_id_not_supported".localized
            static func descFailedFaceID(error: String) -> String {
                return "auth.profile.face_id_failed".localized(with: error)
            }

            static let oldPasswordNotMatched = "auth.profile.old_password_not_matched".localized
            static let descConfirmPassword = "auth.profile.confirm_password_desc".localized
            static let confirmPasswordError = "auth.profile.confirm_password_error".localized
            static let confirmPasswordSuccess = "auth.profile.confirm_password_success".localized
            static let emptyPasswordError = "auth.profile.empty_password_error".localized
        }

        enum PrivacyPolicyView {
            static let navigationTitle = "auth.privacy.navigation_title".localized
            static let intro = "auth.privacy.intro".localized
            static let generalTitle = "auth.privacy.general_title".localized
            static let generalPoints = [
                "auth.privacy.general_point_negative".localized + AppMedical.BTA.Description.negative,
                "auth.privacy.general_point_scanty".localized + AppMedical.BTA.Description.scanty,
                "auth.privacy.general_point_positive1".localized + AppMedical.BTA.Description.positive1,
                "auth.privacy.general_point_positive2".localized + AppMedical.BTA.Description.positive2,
                "auth.privacy.general_point_positive3".localized + AppMedical.BTA.Description.positive3
            ]

            static let definitionTitle = "auth.privacy.definition_title".localized
            static let definitionIntro = "auth.privacy.definition_intro".localized

            struct Definition: Hashable {
                let label: String
                let text: String
                let subpoints: [Definition]?
                init(label: String, text: String, subpoints: [Definition]? = nil) {
                    self.label = label
                    self.text = text
                    self.subpoints = subpoints
                }
            }

            static let definitions: [Definition] = [
                Definition(label: "a.", text: "privacy.definition.a".localized, subpoints: [
                    Definition(label: "i.", text: "privacy.definition.a.i".localized),
                    Definition(label: "ii.", text: "privacy.definition.a.ii".localized),
                    Definition(label: "iii.", text: "privacy.definition.a.iii".localized),
                    Definition(label: "iv.", text: "privacy.definition.a.iv".localized)
                ]),
                Definition(label: "b.", text: "privacy.definition.b".localized),
                Definition(label: "c.", text: "privacy.definition.c".localized),
                Definition(label: "d.", text: "privacy.definition.d".localized),
                Definition(label: "e.", text: "privacy.definition.e".localized),
                Definition(label: "f.", text: "privacy.definition.f".localized),
                Definition(label: "g.", text: "privacy.definition.g".localized),
                Definition(label: "h.", text: "privacy.definition.h".localized)
            ]
        }

        enum PinComponent {
            static let forgotPinText = "auth.pin.forgot_pin".localized
            static let usePasswordButton = "auth.pin.use_password".localized
            static let invalidPinText = "auth.pin.invalid_pin".localized
            static let createChangePinTitle = "auth.pin.create_change_title".localized
            static let revalidateChangePinTitle = "auth.pin.revalidate_change_title".localized
            static let createPinTitle = "auth.pin.create_title".localized
            static let revalidatePinTitle = "auth.pin.revalidate_title".localized
            static let authenticatePinDescription = "auth.pin.authenticate_description".localized
            static let changePinTitle = "auth.pin.change_title".localized
            static let titleCreateChangePin = "auth.pin.title_create_change".localized
            static let titleCreatePin = "auth.pin.title_create".localized
            static let titleAuthenticatePin = "auth.pin.title_authenticate".localized
            static let titleChangePin = "auth.pin.title_change".localized

            static let invalidPinMatchText = "auth.pin.invalid_match".localized
            
            // Forget PIN popup
            static let forgetPinTitle = "auth.pin.forget_title".localized
            static let forgetPinDescription = "auth.pin.forget_description".localized
            static let forgetPinConfirmButton = "auth.pin.forget_confirm".localized
            static let forgetPinCancelButton = "auth.pin.forget_cancel".localized
        }
    }
}
