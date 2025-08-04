//
//  AppText.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 02/08/25.
//

import Foundation

enum AppText {
    enum Icon {
        static let back = "back"
        static let eye = "eye"
        static let faceId = "faceid"
        static let success = "Success"
        static let checkmark = "checkmark"
        static let personFill = "person.fill"
        static let arrowRight = "arrow.right"
        static let lock = "lock"
        static let lockCircleDotted = "lock.circle.dotted"
        static let lockShield = "lock.shield"
        static let doorRightHandOpen = "door.right.hand.open"
        static let docTextMagnifyingglass = "doc.text.magnifyingglass"
        static let docText = "doc.text"
        static let paperplane = "paperplane"
        static let chevronRightIcon = "chevron.right"
        static let photo = "photo"
        static let textBadgeCheckmark = "text.badge.checkmark"
        static let exclamationmarkTriangleFill = "exclamationmark.triangle.fill"
        static let docOnDocFillIcon = "doc.on.doc.fill"
        static let docBadgePlusIcon = "doc.badge.plus"
        static let plus = "plus"
        static let checkmark = "checkmark"
        static let magnifyingglass = "magnifyingglass"
    }

    enum Common {
        static let okButton = "OK"
        static let cancelButton = "Batal"
        static let closeButton = "Tutup"
        static let saveButton = "Simpan"
        static let deleteButton = "Hapus"
        static let editButton = "Ubah"
        static let nextButton = "Lanjutkan"
        static let backButton = "Kembali"
        static let emptyString = ""
        static let errorAlertTitle = "Error"
    }
    
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

        enum UserAccessPin {
            static let successTitle = "PIN Berhasil Diubah"
            static let successDescription = "PIN akses Anda telah berhasil diperbarui"
            static let successButton = "Kembali ke Profile"
        }

        enum Profile {
            static let accountInfoTitle = "Informasi Akun"
            static let emailKey = "Email"
            static let roleKey = "Role"
            static let jobTitleKey = "Jabatan Pekerjaan"
            static let jobTitleValue = "Ahli Teknologi Laboratorium Medik"
            static let healthFacilityKey = "Fasyankes"
            static let healthFacilityDefault = "-"
            static let accountManagementButton = "Manajemen Akun"
            static let editPasswordButton = "Atur Kata Sandi"
            static let editPinButton = "Atur PIN"
            static let faceIdToggle = "Face ID"
            static let privacyPolicyButton = "Kebijakan Privasi"
            static let logoutButton = "Keluar"
            static let navigationTitle = "Profile"
            static var saveChangesButton = "Simpan Perubahan"
        }

        enum PrivacyPolicy {
            static let navigationTitle = "Kebijakan Privasi Oculab"
            static let intro = "Mohon untuk membaca seluruh kebijakan privasi yang terlampir dengan cermat dan seksama sebelum menggunakan setiap fitur dan/atau layanan yang tersedia dalam Oculab"
            static let generalTitle = "Ketentuan Umum"
            static let generalPoints = [
                "Negatif: Tidak ditemukan BTA minimal dalam 100 lapang pandang",
                "Scanty: 1-9 BTA dalam 100 lapang pandang",
                "Positif 1+: 10 – 99 BTA dlm 100 lapang pandang",
                "Positif 2+: 1 – 10 BTA setiap 1 lapang pandang, minimal terdapat di 50 lapang pandang",
                "Positif 3+: ≥ 10 BTA setiap 1 lapang pandang, minimal terdapat di 20 lapang pandang"
            ]
            static let definitionBullet = "•"

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
    }

    enum Examination {
        enum ProgressView {
            static let loadingAnimationName = "loadingPaperplane"
            static let analyzingTitle = "Menginterpretasikan data"
            static let refreshInstruction = "Please scroll down to refresh to update the data"
        }
        
        enum Detail {
            static let navigationTitle = "Detail Pemeriksaan"
            static let patientDataTitle = "Data Pasien"
            static let patientNameKey = "Nama"
            static let patientNikKey = "NIK"
            static let patientDobKey = "Tanggal Lahir"
            static let patientSexKey = "Jenis Kelamin"
            static let patientBpjsKey = "Nomor BPJS"
            static let examinationResult1Title = "Hasil Pemeriksaan Sediaan 1"
            static let examinationResult2Title = "Hasil Pemeriksaan Sediaan 2"
            static let staffInterpretationTitle = "Interpretasi Petugas"
            static let notAvailable = "Belum Tersedia"
            static let slideIdKey = "ID Sediaan"
            static let preparationTypeKey = "Jenis Sediaan"
            static let viewPdfButton = "Lihat PDF"
            static let reportToSitbButton = "Laporkan ke SITB"
            
            // New examination view specific strings
            static let newExaminationTitle = "Pemeriksaan Baru"
            static let dataPemeriksaanStep = "Data Pemeriksaan"
            static let hasilPemeriksaanStep = "Hasil Pemeriksaan"
            static let slideDetailTitle = "Detail Sediaan"
            static let examinationGoalKey = "Tujuan Pemeriksaan"
            static let slideImageTitle = "Gambar Sediaan"
        }
        
        enum GuidelinesOnboarding {
            static let navigationTitle = "Persiapan Pemeriksaan"
            static let continueButton = "Lanjutkan"
            
            struct GuidelineContent {
                let imageName: String
                let title: String
                let description: String
            }
            
            static let guidelines: [GuidelineContent] = [
                GuidelineContent(
                    imageName: "Guideline1",
                    title: "Temukan Lapang Pandang pada Mikroskop",
                    description: "Teteskan minyak imersi pada kaca sediaan dan atur lensa objektif ke perbesaran 100x"
                ),
                GuidelineContent(
                    imageName: "Guideline2",
                    title: "Pasang Handphone pada Adapter",
                    description: "Bersihkan lensa kamera utama dan sejajarkan dengan lubang adapter"
                ),
                GuidelineContent(
                    imageName: "Guideline3",
                    title: "Pasang Adapter pada Mikroskop",
                    description: "Pasang adapter ke lensa okuler dan atur fokus antara mikroskop dan kamera"
                )
            ]
        }
        
        enum SavedResult {
            static let examinationDetailTitle = "Detail Pemeriksaan"
            static let examinationReasonKey = "Alasan Pemeriksaan"
            static let imageResultTitle = "Hasil Gambar"
            static let imageResultInstruction = "Ketuk untuk lihat detail gambar"
            static let interpretationResultTitle = "Hasil Interpretasi"
            static let staffInterpretationTitle = "Interpretasi Petugas"
            static let systemInterpretationTitle = "Interpretasi Sistem"
            static let systemInterpretationWarning = "Interpretasi sistem bukan merupakan hasil akhir untuk pasien"
        }
    }
    
    enum HomeHistory {
        static let navigationTitle = "Riwayat"
        static let loadingMessage = "Memuat data pemeriksaan anda"
        static let emptyStateImageName = "Empty"
        static let noExaminationMessage = "Tidak ada pemeriksaan diselesaikan pada"

        static let navigationTitle = "Tugas Pemeriksaan"
        static let taskSectionTitle = "Tugas Pemeriksaan"
        static let newExaminationButton = "Pemeriksaan Baru"
        static let loadingMessage = "Memuat data pemeriksaan anda"
        static let emptyStateImageName = "Empty"
        static let noTaskMessage = "Anda belum ditugaskan untuk melakukan pemeriksaan"
    }
    
    enum Patient {
        enum Form {
            static let newPatientNavigationTitle = "Data Pasien Baru"
            static let editPatientNavigationTitle = "Ubah Data Pasien"
            static let addNewPatientButton = "Tambahkan Pasien Baru"
            static let savePatientButton = "Simpan Data Pasien"
            static let errorAlertTitle = "Error"
        }
        
        enum List {
            static let navigationTitle = "Riwayat"
            static let searchPlaceholder = "Cari nama pasien"
            static let addNewPatientButton = "Tambah Pasien Baru"
            static let noResultsPrefix = "Tidak ada hasil untuk"
            static let clearSearchButton = "Hapus Pencarian"
            static let magnifyingglassIcon = "magnifyingglass"
        }
        
        enum Detail {
            static let navigationTitle = "Riwayat Pemeriksaan"
            static let patientDataTitle = "Data Pasien"
            static let examinationResultTitle = "Hasil Pemeriksaan"
            static let newExaminationButton = "Pemeriksaan Baru"
            static let loadingPatientMessage = "Loading patient data..."
            static let loadingExaminationsMessage = "Loading examinations..."
            static let noExaminationsMessage = "Belum ada pemeriksaan"
            static let notDeterminedMessage = "Belum ditentukan"
            static let patientNameKey = "Nama"
            static let patientNikKey = "NIK"
            static let patientDobKey = "Tanggal Lahir"
            static let patientSexKey = "Jenis Kelamin"
            static let patientBpjsKey = "Nomor BPJS"
        }
    }
}
