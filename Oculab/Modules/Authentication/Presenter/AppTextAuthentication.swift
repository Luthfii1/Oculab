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
            static let title = "Revolusi Deteksi Bakteri dengan Teknologi AI"
            static let emailPlaceholder = "Contoh: nama.anda@gmail.com"
            static let passwordPlaceholder = "Masukkan kata sandi anda"
            static var buttonText = "Login"
            static let faskesNotRegisteredYet = "Faskes belum terdaftar?"
            static let registerFaskesButtonText = "Daftarkan Faskes"
        }
        
        enum EditPasswordView {
            static let successUpdatePasswordTitle = "Berhasil mengubah kata sandi"
            static let successUpdatePasswordMessage = "Anda telah berhasil mengubah kata sandi akun anda"
            static let successUpdatePasswordButtonText = "Kembali ke profil"
            static let navigationTitle = "Atur Kata Sandi"
            static let currentPasswordTitle = "Kata Sandi Saat Ini"
            static let currentPasswordPlaceholder = AppForm.placeholder("Kata Sandi")
            static let newPasswordTitle = "Kata Sandi Baru"
            static let newPasswordPlaceholder = AppForm.placeholder("Kata Sandi Baru")
            static let newPasswordDescription = "Kata sandi harus terdiri dari minimal 8 karakter"
            static let confirmPasswordTitle = "Konfirmasi Kata Sandi Baru"
            static let confirmPasswordPlaceholder = AppForm.placeholder("Konfirmasi Kata Sandi Baru")
        }

        enum UserAccessPinView {
            static let successTitle = "PIN Berhasil Diubah"
            static let successDescription = "PIN akses Anda telah berhasil diperbarui"
            static let successButton = AppAction.back + " ke " + AppNav.profile
        }

        enum ProfileView {
            static let accountInfoTitle = "Informasi Akun"
            static let jobTitleKey = "Jabatan Pekerjaan"
            static let jobTitleValue = "Ahli Teknologi Laboratorium Medik"
            static let healthFacilityKey = "Fasyankes"
            static let editPasswordButton = "Atur Kata Sandi"
            static let editPinButton = "Atur PIN"
            static let faceIdToggle = "Face ID"
            static let privacyPolicyButton = "Kebijakan Privasi"
        }

        enum PrivacyPolicyView {
            static let navigationTitle = "Kebijakan Privasi Oculab"
            static let intro = "Mohon untuk membaca seluruh kebijakan privasi yang terlampir dengan cermat dan seksama sebelum menggunakan setiap fitur dan/atau layanan yang tersedia dalam Oculab"
            static let generalTitle = "Ketentuan Umum"
            static let generalPoints = [
                "Negatif: Tidak ditemukan BTA minimal dalam 100 lapang pandang",
                "Scanty: 1-9 BTA dalam 100 lapang pandang",
                "Positif 1+: 10 - 99 BTA dlm 100 lapang pandang",
                "Positif 2+: 1 - 10 BTA setiap 1 lapang pandang, minimal terdapat di 50 lapang pandang",
                "Positif 3+: ≥ 10 BTA setiap 1 lapang pandang, minimal terdapat di 20 lapang pandang"
            ]

            static let definitionTitle = "Definisi"
            static let definitionIntro = "Setiap kata atau istilah berikut yang digunakan di dalam Kebijakan Privasi ini memiliki arti seperti berikut di bawah, kecuali jika kata atau istilah yang bersangkutan di dalam pemakaiannya dengan tegas menentukan lain:"

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
            static let forgotPinText = "Lupa PIN?"
            static let usePasswordButton = "Gunakan Password"
        }
    }
}