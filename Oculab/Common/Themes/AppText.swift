//
//  AppText.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 02/08/25.
//

import Foundation

// NOTE: Authentication Module Texts
typealias AppTextAuthLogin = AppText.Authentication.LoginView
typealias AppTextAuthEditPassword = AppText.Authentication.EditPasswordView
typealias AppTextAuthUserAccessPin = AppText.Authentication.UserAccessPinView
typealias AppTextAuthProfile = AppText.Authentication.ProfileView
typealias AppTextAuthPrivacyPolicy = AppText.Authentication.PrivacyPolicyView
typealias AppTextAuthCompPin = AppText.Authentication.PinComponent

// NOTE: Examination Module Texts
typealias AppTextExamProgress = AppText.Examination.ProgressView
typealias AppTextExamDetail = AppText.Examination.DetailViews
typealias AppTextExamGuidelines = AppText.Examination.GuidelinesOnboardingView
typealias AppTextExamSavedResult = AppText.Examination.SavedResultView
typealias AppTextExamCompConfirmPopups = AppText.Examination.ConfirmationPopupsComponent
typealias AppTextExamCompGradingCard = AppText.Examination.GradingCardComponent
typealias AppTextExamCompImageSection = AppText.Examination.ImageSectionComponent
typealias AppTextExamCompInterpretationSection = AppText.Examination.InterpretationSectionComponent
typealias AppTextExamCompLabInfo = AppText.Examination.LaborantInfoComponent
typealias AppTextExamCompHeaderView = AppText.Examination.HeaderViewComponent
typealias AppTextExamCompFolderCard = AppText.Examination.FolderCardComponent
typealias AppTextExamCompExtendableCard = AppText.Examination.ExtendableCardComponent

// Note: HomeHistory Module Texts
typealias AppTextHomeHistory = AppText.HomeHistory
typealias AppTextHomeHistCompFinishedExamCard = AppText.HomeHistory.FinishedExaminationCardComponent
typealias AppTextHomeHistCompStatistic = AppText.HomeHistory.StatisticComponent
typealias AppTextHomeHistCompWeeklyCalendar = AppText.HomeHistory.WeeklyCalendarComponent
typealias AppTextHomeHistCompHomeActivity = AppText.HomeHistory.HomeActivityComponent
typealias AppTextHomeHistCompButtonActivity = AppText.HomeHistory.ButtonActivityComponent
typealias AppTextHomeHistCompHalfCircleProgress = AppText.HomeHistory.HalfCircleProgressComponent

// NOTE: Patient Module Texts
typealias AppTextPatientDetail = AppText.Patient.DetailView
typealias AppTextPatientForm = AppText.Patient.FormView
typealias AppTextPatientList = AppText.Patient.ListView
typealias AppTextPatientCompCard = AppText.Patient.PatientCardComponent
typealias AppTextPatientCompFormField = AppText.Patient.PatientFormFieldComponent

// NOTE: UserManagement Module Texts
typealias AppTextUserMgmtView = AppText.UserManagement.UserManagementView
typealias AppTextUserMgmtNewUserForm = AppText.UserManagement.NewUserFormView
typealias AppTextUserMgmtEditUserForm = AppText.UserManagement.EditUserFormView
typealias AppTextUserMgmtUserListView = AppText.UserManagement.UserListView
typealias AppTextUserMgmtCompBottomSheet = AppText.UserManagement.BottomSheetMenuComponent

// NOTE: VideoRecord Module Texts
typealias AppTextVideoRecordView = AppText.VideoRecord.VideoRecordView
typealias AppTextVideoRecordInstruction = AppText.VideoRecord.InstructionRecordView
typealias AppTextVideoRecordStitched = AppText.VideoRecord.StitchedImageView
typealias AppTextVideoRecordFullScreen = AppText.VideoRecord.FullScreenVideoPlayerView
typealias AppTextVideoRecordCompCamera = AppText.VideoRecord.CameraViewComponent
typealias AppTextVideoRecordCompPreview = AppText.VideoRecord.VideoPreviewComponent
typealias AppTextVideoRecordCompInput = AppText.VideoRecord.VideoInputComponent

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
        static let docTextFill = "doc.text.fill"
        static let paperplane = "paperplane"
        static let chevronRightIcon = "chevron.right"
        static let photo = "photo"
        static let textBadgeCheckmark = "text.badge.checkmark"
        static let exclamationmarkTriangleFill = "exclamationmark.triangle.fill"
        static let docOnDocFillIcon = "doc.on.doc.fill"
        static let docBadgePlusIcon = "doc.badge.plus"
        static let plus = "plus"
        static let magnifyingglass = "magnifyingglass"
        static let deleteLeftFill = "delete.left.fill"
        static let robot = "robot"
        static let rectangleStackFill = "rectangle.stack.fill"
        static let infoCircle = "info.circle"
        static let xmark = "xmark"
        static let chevronDown = "chevron.down"
        static let chevronUp = "chevron.up"
        static let confirmLeave = "Confirm-Leave"
        static let confirm = "Confirm"
        static let trayFullFill = "tray.full.fill"
        static let calendar = "calendar"
        static let ellipsis = "ellipsis"
        static let pencil = "pencil"
        static let trash = "trash"
        static let chevronLeft = "chevron.left"
        static let addAccount = "AddAccount"
        static let xmarkCircleFill = "xmark.circle.fill"
        static let arrowCounterclockwise = "arrow.counterclockwise"
        static let camera = "camera"
        static let cameraFill = "camera.fill"
        static let preparationSectionIcon = "list.number"
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
        enum LoginView {
            static let title = "Revolusi Deteksi Bakteri dengan Teknologi AI"
            static let emailTitle = "Email"
            static let emailPlaceholder = "Contoh: your.name@gmail.com"
            static let passwordTitle = "Kata Sandi"
            static let passwordPlaceholder = "Masukkan kata sandi anda"
            static var buttonText = "Login"
            static let faskesNotRegisteredYet = "Faskes belum terdaftar?"
            static let registerFaskesButtonText = "Daftarkan Faskes"
        }
        
        enum EditPasswordView {
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

        enum UserAccessPinView {
            static let successTitle = "PIN Berhasil Diubah"
            static let successDescription = "PIN akses Anda telah berhasil diperbarui"
            static let successButton = "Kembali ke Profile"
        }

        enum ProfileView {
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

        enum PrivacyPolicyView {
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

        enum PinComponent {
            static let forgotPinText = "Lupa PIN?"
            static let usePasswordButton = "Gunakan Password"
        }
    }

    enum Examination {
        enum ProgressView {
            static let loadingAnimationName = "loadingPaperplane"
            static let analyzingTitle = "Menginterpretasikan data"
            static let refreshInstruction = "Please scroll down to refresh to update the data"
        }
        
        enum DetailViews {
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
        
        enum GuidelinesOnboardingView {
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
        
        enum SavedResultView {
            static let examinationDetailTitle = "Detail Pemeriksaan"
            static let examinationReasonKey = "Alasan Pemeriksaan"
            static let imageResultTitle = "Hasil Gambar"
            static let imageResultInstruction = "Ketuk untuk lihat detail gambar"
            static let interpretationResultTitle = "Hasil Interpretasi"
            static let staffInterpretationTitle = "Interpretasi Petugas"
            static let systemInterpretationTitle = "Interpretasi Sistem"
            static let systemInterpretationWarning = "Interpretasi sistem bukan merupakan hasil akhir untuk pasien"
        }
        
        enum ConfirmationPopupsComponent {
            static let unfinishedExaminationTitle = "Pemeriksaan Belum Selesai"
            static let unfinishedExaminationDescription = "Pemeriksaan disimpan sebagai draft dan dapat diakses di halaman riwayat"
            static let exitButton = "Keluar"
            static let reviewAgainButton = "Periksa Kembali"
            static let saveResultTitle = "Simpan Hasil Pemeriksaan"
            static let saveResultDescription = "Hasil pemeriksaan yang sudah disimpan tidak dapat diubah kembali"
            static let saveButton = "Simpan"
        }
        
        enum GradingCardComponent {
            static let confidenceLevelText = "confidence level"
        }
        
        enum ImageSectionComponent {
            static let imageResultTitle = "Hasil Gambar"
            static let imageResultInstruction = "Ketuk untuk lihat detail gambar"
        }
        
        enum InterpretationSectionComponent {
            static let interpretationResultTitle = "Hasil Interpretasi"
            static let staffInterpretationTitle = "Interpretasi Petugas"
            static let selectCategoryPlaceholder = "Pilih kategori"
            static let btaCountTitle = "Jumlah BTA"
            static let btaCountPlaceholder = "Contoh: 8"
            static let staffNotesTitle = "Catatan Petugas"
            static let staffNotesPlaceholder = "Contoh: Hanya terdapat 20 bakteri dari 60 lapangan pandang yang terkumpul"
            static let doneButton = "Selesai"
        }
        
        enum LaborantInfoComponent {
            static let examinationOfficerTitle = "Petugas Pemeriksaan"
            static let assignedByTitle = "Ditugaskan Oleh"
        }
        
        enum FolderCardComponent {
            static let imageCountSuffix = "Gambar"
        }
        
        enum HeaderViewComponent {
            static let newExaminationTitle = "Pemeriksaan Baru"
        }
        
        enum ExtendableCardComponent {
            static let unknownTitle = "Unknown"
        }
    }
    
    enum HomeHistory {
        static let navigationTitleHistory = "Riwayat"
        static let loadingMessage = "Memuat data pemeriksaan anda"
        static let emptyStateImageName = "Empty"
        static let noExaminationMessage = "Tidak ada pemeriksaan diselesaikan pada"

        static let navigationTitleHome = "Tugas Pemeriksaan"
        static let taskSectionTitle = "Tugas Pemeriksaan"
        static let newExaminationButton = "Pemeriksaan Baru"
        static let noTaskMessage = "Anda belum ditugaskan untuk melakukan pemeriksaan"
        
        enum FinishedExaminationCardComponent {
            static let patientLabel = "Pasien"
            static let dpjpLabel = "DPJP"
            static let positiveKeyword = "positif"
            static let positiveAltKeyword = "positive"
        }
        
        enum StatisticComponent {
            static let title = "Statistik Pemeriksaan"
            static let tasksCompletedSuffix = "Tugas Selesai"
            static let fromTasksPrefix = "dari"
            static let tasksInTotalSuffix = "Tugas"
            static let positiveLabel = "Positif"
            static let negativeLabel = "Negatif"
            static let pendingLabel = "Pending"
        }
        
        enum WeeklyCalendarComponent {
            static let title = "Pemeriksaan Selesai"
            static let selectDatePickerTitle = "Select a Date"
        }
        
        enum HomeActivityComponent {
            static let examinationOfficerLabel = "Petugas Pemeriksaan"
        }
        
        enum ButtonActivityComponent {
            // This component doesn't have hardcoded strings, but keeping for consistency
        }
        
        enum HalfCircleProgressComponent {
            static let percentageSuffix = "%"
        }
    }
    
    enum Patient {
        enum FormView {
            static let newPatientNavigationTitle = "Data Pasien Baru"
            static let editPatientNavigationTitle = "Ubah Data Pasien"
            static let addNewPatientButton = "Tambahkan Pasien Baru"
            static let savePatientButton = "Simpan Data Pasien"
            static let errorAlertTitle = "Error"
        }
        
        enum ListView {
            static let navigationTitle = "Riwayat"
            static let searchPlaceholder = "Cari nama pasien"
            static let addNewPatientButton = "Tambah Pasien Baru"
            static let noResultsPrefix = "Tidak ada hasil untuk"
            static let clearSearchButton = "Hapus Pencarian"
            static let magnifyingglassIcon = "magnifyingglass"
        }
        
        enum DetailView {
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
        
        enum PatientCardComponent {
            static let birthDatePrefix = "Tanggal Lahir: "
        }
        
        enum PatientFormFieldComponent {
            static let nameTitle = "Nama"
            static let namePlaceholder = "John Doe"
            static let nikTitle = "NIK"
            static let nikPlaceholder = "Contoh: 167012039484700"
            static let birthDateTitle = "Tanggal Lahir"
            static let birthDatePlaceholder = "Pilih Tanggal"
            static let genderTitle = "Jenis Kelamin"
            static let femaleChoice = "Perempuan"
            static let maleChoice = "Laki-laki"
            static let bpjsTitle = "Nomor BPJS (opsional)"
            static let bpjsPlaceholder = "Contoh: 1240630077675"
            static let doneButton = "Selesai"
        }
    }
    
    enum UserManagement {
        enum UserManagementView {
            static let navigationTitle = "Manajemen Akun"
            static let searchPlaceholder = "Cari akun"
            static let addNewAccountButton = "Tambah Akun Baru"
            static let noResultsPrefix = "Tidak ada hasil untuk"
            static let clearSearchButton = "Hapus Pencarian"
            static let deleteAccountTitle = "Hapus akun"
            static let deleteAccountDescription = "Akun yang sudah dihapus tidak dapat dikembalikan lagi."
            static let deleteAccountButton = "Hapus Akun"
            static let backButton = "Kembali"
            static let deleteSuccessTitle = "Berhasil Menghapus Akun"
            static let deleteSuccessDescription = "Akun berhasil dihapus"
            static let deletionFailedTitle = "Deletion Failed"
            static let unknownErrorMessage = "Unknown error"
        }
        
        enum NewUserFormView {
            static let navigationTitle = "Buat Akun Baru"
            static let successTitle = "Berhasil membuat Akun"
            static let successDescriptionPrefix = "Anda telah berhasil menambahkan akun baru untuk"
            static let successDescriptionSuffix = "dengan role"
            static let createAnotherAccountButton = "Buat Akun Lain"
            static let backToAccountListButton = "Kembali ke Daftar Akun"
            static let roleTitle = "Role"
            static let roleLabPlaceholder = "Laboran"
            static let roleAdminChoice = "Admin"
            static let nameTitle = "Nama"
            static let namePlaceholder = "John Doe"
            static let emailTitle = "Email"
            static let emailPlaceholder = "john@gmail.com"
            static let registerAccountButton = "Daftarkan Akun"
            static let registrationFailedTitle = "Registration Failed"
            static let unknownErrorMessage = "Unknown error"
        }
        
        enum EditUserFormView {
            static let navigationTitle = "Edit Akun"
            static let successTitle = "Berhasil mengubah Akun"
            static let successDescriptionPrefix = "Anda telah berhasil mengubah akun untuk"
            static let successDescriptionSuffix = "dengan role"
            static let backToAccountListButton = "Kembali ke Daftar Akun"
            static let roleTitle = "Role"
            static let nameTitle = "Nama"
            static let namePlaceholder = "Masukkan nama"
            static let emailTitle = "Email"
            static let emailPlaceholder = "Email"
            static let emailDisabledDescription = "Email tidak dapat diubah"
            static let saveChangesButton = "Simpan Perubahan"
            static let cancelButton = "Batal"
            static let editFailedTitle = "Edit Failed"
            static let unknownErrorMessage = "Unknown error"
        }
        
        enum UserListView {
            // This component doesn't have specific hardcoded strings, but keeping for consistency
        }
        
        enum BottomSheetMenuComponent {
            static let editAccountDetailsButton = "Ubah Detail Akun"
            static let deleteAccountButton = "Hapus Akun"
        }
    }
    
    enum VideoRecord {
        enum VideoRecordView {
            static let cameraAccessDeniedTitle = "Camera Access Denied"
            static let cameraAccessDeniedMessage = "Please enable camera access for Oculab in Settings to record video"
            static let goToSettingsButton = "Go to Settings"
            static let cancelButton = "Cancel"
        }
        
        enum InstructionRecordView {
            static let navigationTitle = "Instruksi Pemeriksaan"
            static let preparationSectionTitle = "Persiapan Pemeriksaan"
            static let recordingSectionTitle = "Instruksi Pengambilan Gambar"
            static let startRecordingButton = "Mulai Pengambilan Gambar"
        }
        
        enum StitchedImageView {
            static let navigationTitle = "Stitched Image"
            static let noImageAvailableMessage = "No stitched image available"
        }
        
        enum FullScreenVideoPlayerView {
            // Empty enum for consistency, no specific strings needed
        }
        
        enum CameraViewComponent {
            static let cameraAccessAlertTitle = "Camera Access"
            static let cameraAccessAlertMessage = "Please enable camera and microphone access in settings"
            static let settingsButton = "Settings"
            static let cancelButton = "Cancel"
        }
        
        enum VideoPreviewComponent {
            static let saveVideoButton = "Simpan Video"
            static let retakeVideoButton = "Ambil Ulang"
        }
        
        enum VideoInputComponent {
            static let requiredFieldIndicator = "*"
            static let takeVideoButton = "Ambil Gambar"
            static let previewVideoButton = "Preview Video"
            static let videoErrorAlertTitle = "Gagal Memutar Video"
            static let videoErrorAlertMessage = "Video tidak dapat diputar. Silakan rekam ulang sampel."
            static let videoErrorDismissButton = "Kembali"
        }
    }
}
