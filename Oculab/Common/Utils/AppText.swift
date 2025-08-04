//
//  AppText.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 02/08/25.
//

import Foundation

enum AppText {
    enum Authentication {
        enum Login {
            static let title = "Revolusi Deteksi Bakteri dengan Teknologi AI"
            static let emailTitle = "Email"
            static let emailPlaceholder = "Contoh: your.name@gmail.com"
            static let passwordTitle = "Kata Sandi"
            static let passwordPlaceholder = "Masukkan kata sandi anda"
            static var buttonText = "Login"
            static let faskesNotRegisteredYet = "Faskes belum terdaftar?"
            static let registerFaskesButtonText = "Daftarkan Faskes"
        }
        
        enum EditPassword {
            static let successUpdatePasswordTitle = "Berhasil mengubah Password"
            static let successUpdatePasswordMessage = "Anda telah berhasil mengubah password akun anda"
            static let successUpdatePasswordButtonText = "Kembali ke profile"
            static let navigationTitle = "Atur Password"
            static let currentPasswordTitle = "Password Saat Ini"
            static let currentPasswordPlaceholder = "Masukkan Password"
            static let newPasswordTitle = "Password Baru"
            static let newPasswordPlaceholder = "Masukkan Password Baru"
            static let newPasswordDescription = "Password harus terdiri dari minimal 8 karakter"
            static let confirmPasswordTitle = "Konfirmasi Password Baru"
            static let confirmPasswordPlaceholder = "Masukkan Konfirmasi Password Baru"
        }
    }

    enum Icon {
        static let back = "back"
        static let eye = "eye"
        static let faceId = "faceid"
        static let success = "Success"
        static let checkmark = "checkmark"
    }
}
