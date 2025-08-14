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

extension AppText {
    enum Authentication {
        enum LoginView {
            static let title = "auth.login.title".localized
            static let emailPlaceholder = "auth.login.email.placeholder".localized
            static let passwordPlaceholder = "auth.login.password.placeholder".localized
            static let buttonText = "auth.login.button".localized
            static let faskesNotRegisteredYet = "auth.login.not_registered".localized
            static let registerFaskesButtonText = "auth.login.register_facility".localized
            static let loginFailedText = "auth.login.failed".localized
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
                Definition(label: "a.", text: "“OCULAB” adalah platform yang dipergunakan di wilayah Republik Indonesia untuk tujuan:", subpoints: [
                    Definition(label: "i.", text: "Mencakup Data Sumber Daya Manusia Kesehatan baik tenaga medis, tenaga keteknisian medis, dan tenaga Kesehatan lainnya yang diverifikasi oleh Dinas Kesehatan Kabupaten/ Kota dan divalidasi oleh Dinas Kesehatan Provinsi."),
                    Definition(label: "ii.", text: "Penyelenggaraan informasi Sumber Daya Manusia Kesehatan;"),
                    Definition(label: "iii.", text: "Sistem informasi Kesehatan bagi Sumber Daya Manusia Kesehatan; dan"),
                    Definition(label: "iv.", text: "upaya kesehatan lainnya yang bersifat promotif, preventif, kuratif, dan rehabilitatif serta tujuan-tujuan lainnya selama diizinkan berdasarkan ketentuan peraturan perundang-undangan yang berlaku.")
                ]),
                Definition(label: "b.", text: "“Platform” adalah platform SATUSEHAT SDMK, sistem, dan/atau aplikasi layanan integrasi dan interoperabilitas data Sumber Daya Manusia Kesehatan yang dikelola dan diselenggarakan oleh Kementerian Kesehatan. Termasuk daftar Riwayat hidup, riwayat Pendidikan, riwayat pekerjaan dan kebutuhan data terkait lainnya."),
                Definition(label: "c.", text: "“Platform” adalah platform SATUSEHAT SDMK, sistem, dan/atau aplikasi layanan integrasi dan interoperabilitas data Sumber Daya Manusia Kesehatan yang dikelola dan diselenggarakan oleh Kementerian Kesehatan. Termasuk daftar Riwayat hidup, riwayat Pendidikan, riwayat pekerjaan dan kebutuhan data terkait lainnya."),
                Definition(label: "d.", text: "“Pengguna”, berarti setiap Sumber Daya Manusia Kesehatan yang menggunakan SATUSEHAT SDMK."),
                Definition(label: "e.", text: "“Tenaga Kesehatan”, berarti setiap orang yang mengabdikan diri dalam bidang Kesehatan serta memiliki pengetahuan dan/ atau keterampilan melalui Pendidikan di bidang Kesehatan yang untuk jenis tertentu memerlukan kewenangan untuk melakukan Upaya Kesehatan."),
                Definition(label: "f.", text: "“Fasilitas Pelayanan Kesehatan”, suatu alat dan/ atau tempat yang digunakan untuk menyelenggarakan Upaya pelayanan Kesehatan, baik promotif, preventif, kuratif maupun rehabilitatif yang dilakukan oleh pemerintah, pemerintah daerah, dan/ atau Masyarakat."),
                Definition(label: "g.", text: "“Data Pribadi” atau “Data Kesehatan” berarti setiap dan seluruh data pribadi dan data kondisi kesehatan Pengguna, termasuk namun tidak terbatas pada nama, nomor identifikasi, lokasi Pengguna, kontak Pengguna, serta dokumen dan data lainnya sebagaimana diminta pada formulir pendaftaran akun atau informasi kesehatan termasuk setiap dan seluruh data kesehatan Pengguna seperti rekam medis, jenis kelamin, kondisi kesehatan, pengobatan, alergi, vaksinasi, imunisasi, tindakan, riwayat medis, resep, laporan, anjuran dan informasi medis atau catatan kondisi kesehatan lainnya."),
                Definition(label: "h.", text: "“Pengendali Data” adalah setiap orang, badan publik, dan/atau organisasi internasional yang bertindak sendiri-sendiri atau bersama-sama dalam menentukan tujuan dan melakukan kendali pemrosesan Data Pribadi atau Data Kesehatan atau informasi lainnya. “Prosesor Data” adalah setiap orang, badan publik, dan/atau organisasi internasional yang bertindak sendiri-sendiri atau bersama-sama dalam melakukan pemrosesan Data Pribadi atau Data Kesehatan atau informasi lainnya yang ditunjuk Pengendali Data.")
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
        }
    }
}
