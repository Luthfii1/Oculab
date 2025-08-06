//
//  AppText.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 02/08/25.
//

import Foundation

// MARK: - Convenient Type Aliases (Shorter access)
typealias AppAction = AppText.Action
typealias AppState = AppText.State
typealias AppLabel = AppText.Label
typealias AppValue = AppText.Value
typealias AppPatient = AppText.PatientData
typealias AppMedical = AppText.Medical
typealias AppSearch = AppText.Search
typealias AppForm = AppText.Form
typealias AppNav = AppText.Navigation
typealias AppData = AppText.Data
typealias AppIcon = AppText.SystemIcon
typealias AppImage = AppText.AppIcon

// MARK: Authentication Module Texts
typealias AppTextAuthLogin = AppText.Authentication.LoginView
typealias AppTextAuthEditPassword = AppText.Authentication.EditPasswordView
typealias AppTextAuthUserAccessPin = AppText.Authentication.UserAccessPinView
typealias AppTextAuthProfile = AppText.Authentication.ProfileView
typealias AppTextAuthPrivacyPolicy = AppText.Authentication.PrivacyPolicyView
typealias AppTextAuthCompPin = AppText.Authentication.PinComponent

// MARK: Examination Module Texts
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

// MARK: HomeHistory Module Texts
typealias AppTextHomeHistory = AppText.HomeHistory
typealias AppTextHomeHistCompFinishedExamCard = AppText.HomeHistory.FinishedExaminationCardComponent
typealias AppTextHomeHistCompStatistic = AppText.HomeHistory.StatisticComponent
typealias AppTextHomeHistCompWeeklyCalendar = AppText.HomeHistory.WeeklyCalendarComponent
typealias AppTextHomeHistCompHomeActivity = AppText.HomeHistory.HomeActivityComponent
typealias AppTextHomeHistCompButtonActivity = AppText.HomeHistory.ButtonActivityComponent
typealias AppTextHomeHistCompHalfCircleProgress = AppText.HomeHistory.HalfCircleProgressComponent

// MARK: Patient Module Texts
typealias AppTextPatientDetail = AppText.Patient.DetailView
typealias AppTextPatientForm = AppText.Patient.FormView
typealias AppTextPatientList = AppText.Patient.ListView
typealias AppTextPatientCompCard = AppText.Patient.PatientCardComponent
typealias AppTextPatientCompFormField = AppText.Patient.PatientFormFieldComponent

// MARK: UserManagement Module Texts
typealias AppTextUserMgmtView = AppText.UserManagement.UserManagementView
typealias AppTextUserMgmtNewUserForm = AppText.UserManagement.NewUserFormView
typealias AppTextUserMgmtEditUserForm = AppText.UserManagement.EditUserFormView
typealias AppTextUserMgmtUserListView = AppText.UserManagement.UserListView
typealias AppTextUserMgmtCompBottomSheet = AppText.UserManagement.BottomSheetMenuComponent

// MARK: VideoRecord Module Texts
typealias AppTextVideoRecordView = AppText.VideoRecord.VideoRecordView
typealias AppTextVideoRecordInstruction = AppText.VideoRecord.InstructionRecordView
typealias AppTextVideoRecordStitched = AppText.VideoRecord.StitchedImageView
typealias AppTextVideoRecordFullScreen = AppText.VideoRecord.FullScreenVideoPlayerView
typealias AppTextVideoRecordCompCamera = AppText.VideoRecord.CameraViewComponent
typealias AppTextVideoRecordCompPreview = AppText.VideoRecord.VideoPreviewComponent
typealias AppTextVideoRecordCompInput = AppText.VideoRecord.VideoInputComponent

// MARK: TaskAssignment Module Texts
typealias AppTextTaskAssignInputPatient = AppText.TaskAssignment.InputPatientDataView
typealias AppTextTaskAssignInputExam = AppText.TaskAssignment.InputExaminationDataView
typealias AppTextTaskAssignCompDateField = AppText.TaskAssignment.DateFieldComponent
typealias AppTextTaskAssignCompPatientDisplay = AppText.TaskAssignment.PatientDisplayFieldComponent

// MARK: Analysist Module Texts
typealias AppTextAnalysisResult = AppText.Analysist.AnalysisResultView
typealias AppTextAnalysisInformation = AppText.Analysist.InformationPageView
typealias AppTextAnalysisFOVDetail = AppText.Analysist.FOVDetailView
typealias AppTextAnalysisPDF = AppText.Analysist.PDFView
typealias AppTextAnalysisFOVAlbum = AppText.Analysist.FOVAlbumView
typealias AppTextAnalysisCompZoomable = AppText.Analysist.ZoomableImageComponent

enum AppText {
    // MARK: - Core System Icons (Reusable across all modules)
    enum SystemIcon {
        static let back = "chevron.left"
        static let forward = "chevron.right"
        static let up = "chevron.up"
        static let down = "chevron.down"
        static let close = "xmark"
        static let add = "plus"
        static let edit = "pencil"
        static let delete = "trash"
        static let search = "magnifyingglass"
        static let settings = "gearshape"
        static let info = "info.circle"
        static let warning = "exclamationmark.triangle.fill"
        static let success = "checkmark.circle.fill"
        static let error = "xmark.circle.fill"
        static let camera = "camera"
        static let cameraFill = "camera.fill"
        static let photo = "photo"
        static let document = "doc.text"
        static let documentFill = "doc.text.fill"
        static let share = "square.and.arrow.up"
        static let refresh = "arrow.counterclockwise"
        static let calendar = "calendar"
        static let ellipsis = "ellipsis"
        static let eye = "eye"
        static let faceId = "faceid"
        static let checkmark = "checkmark"
        static let personFill = "person.fill"
        static let arrowRight = "arrow.right"
        static let lock = "lock"
        static let lockCircleDotted = "lock.circle.dotted"
        static let lockShield = "lock.shield"
        static let doorRightHandOpen = "door.right.hand.open"
        static let docTextMagnifyingglass = "doc.text.magnifyingglass"
        static let paperplane = "paperplane"
        static let textBadgeCheckmark = "text.badge.checkmark"
        static let docOnDocFill = "doc.on.doc.fill"
        static let docBadgePlus = "doc.badge.plus"
        static let deleteLeftFill = "delete.left.fill"
        static let robot = "robot"
        static let rectangleStackFill = "rectangle.stack.fill"
        static let trayFullFill = "tray.full.fill"
        static let preparationSection = "list.number"
    }
    
    // MARK: - App Specific Icons
    enum AppIcon {
        static let logo = "logo"
        static let destroy = "Destroy"
        static let confirm = "Confirm"
        static let confirmLeave = "Confirm-Leave"
        static let contrast = "Contrast"
        static let brightness = "Brightness"
        static let comment = "Comment"
        static let addAccount = "AddAccount"
        static let phone = "phoneIcon"
        static let envelope = "envelopeIcon"
        static let line = "line"
        static let backWhite = "back_white"
        static let back = "back"
        static let success = "Success"
    }
    
    // MARK: - Universal Actions (Used across all modules)
    enum Action {
        static let ok = "OK"
        static let cancel = "Batal"
        static let save = "Simpan"
        static let delete = "Hapus"
        static let edit = "Ubah"
        static let close = "Tutup"
        static let next = "Lanjutkan"
        static let back = "Kembali"
        static let done = "Selesai"
        static let exit = "Keluar"
        static let settings = "Pengaturan"
        static let retry = "Coba Lagi"
        static let refresh = "Refresh"
        static let continue = "Lanjutkan"
        static let confirm = "Konfirmasi"
        
        // Common button patterns
        static let saveChanges = "Simpan Perubahan"
        static let saveData = "Simpan Data"
        static let addNew = "Tambah Baru"
        static let editData = "Ubah Data"
        static let deleteData = "Hapus Data"
        
        // Dynamic functions for custom combinations
        static func save(_ itemType: String) -> String {
            return "Simpan \(itemType)"
        }
        
        static func add(_ itemType: String) -> String {
            return "Tambah \(itemType)"
        }
        
        static func edit(_ itemType: String) -> String {
            return "Ubah \(itemType)"
        }
        
        static func delete(_ itemType: String) -> String {
            return "Hapus \(itemType)"
        }
        
        static func view(_ itemType: String) -> String {
            return "Lihat \(itemType)"
        }
    }
    
    // MARK: - Universal States (Used across all modules)
    enum State {
        static let loading = "Memuat..."
        static let empty = "Kosong"
        static let error = "Error"
        static let success = "Berhasil"
        static let pending = "Pending"
        static let notAvailable = "Belum Tersedia"
        static let unknown = "Tidak Diketahui"
        static let completed = "Selesai"
        static let inProgress = "Sedang Berlangsung"
        
        // Dynamic status patterns
        static func loading(_ action: String) -> String {
            return "Memuat \(action)..."
        }
        
        static func success(_ action: String) -> String {
            return "Berhasil \(action)"
        }
        
        static func failed(_ action: String) -> String {
            return "Gagal \(action)"
        }
    }
    
    // MARK: - Universal Labels (Common field names)
    enum Label {
        static let name = "Nama"
        static let email = "Email"
        static let password = "Kata Sandi"
        static let phone = "Telepon"
        static let address = "Alamat"
        static let date = "Tanggal"
        static let time = "Waktu"
        static let MARKs = "Catatan"
        static let description = "Deskripsi"
        static let title = "Judul"
        static let type = "Jenis"
        static let status = "Status"
        static let result = "Hasil"
        static let category = "Kategori"
        static let role = "Role"
    }
    
    // MARK: - Common Values
    enum Value {
        static let empty = ""
        static let defaultStrike = "-"
        static let bullet = "•"
        static let percentage = "%"
        static let required = "*"
        static let unknownError = "Terjadi Kesalahan"
        static let unknownMessage = "Pesan tidak diketahui"
    }
    
    // MARK: - Patient Data (Reusable across modules)
    enum PatientData {
        static let name = "Nama"
        static let nik = "NIK"
        static let dateOfBirth = "Tanggal Lahir"
        static let gender = "Jenis Kelamin"
        static let bpjsNumber = "Nomor BPJS"
        static let age = "Umur"
        static let ageSuffix = " Tahun"
        
        enum Gender {
            static let male = "Laki-laki"
            static let female = "Perempuan"
        }
        
        enum Placeholder {
            static let name = "Masukkan nama pasien"
            static let nik = "Contoh: 167012039484700"
            static let bpjs = "Contoh: 1240630077675"
            static let selectDate = "Pilih Tanggal"
        }
    }
    
    // MARK: - Medical Terms (Reusable across examination modules)
    enum Medical {
        enum BTA {
            static let negative = "Negatif"
            static let scanty = "Scanty"
            static let positive1 = "Positif (1+)"
            static let positive2 = "Positif (2+)"
            static let positive3 = "Positif (3+)"
            
            enum Description {
                static let negative = "Tidak ditemukan BTA dalam 100 lapang pandang"
                static let scanty = "Ditemukan 1-9 BTA dalam 100 lapang pandang"
                static let positive1 = "Ditemukan 10-99 BTA dalam 100 lapang pandang"
                static let positive2 = "Ditemukan 1-9 BTA dalam setiap lapang pandang, minimal dalam 50 lapang pandang"
                static let positive3 = "Ditemukan ≥10 BTA dalam setiap lapang pandang, minimal dalam 20 lapang pandang"
            }
        }
        
        enum Examination {
            static let purpose = "Tujuan Pemeriksaan"
            static let result = "Hasil Pemeriksaan"
            static let interpretation = "Interpretasi"
            static let staffInterpretation = "Interpretasi Petugas"
            static let systemInterpretation = "Interpretasi Sistem"
            static let bacteriaCount = "Jumlah Bakteri"
            static let slideId = "ID Sediaan"
            static let specimenType = "Jenis Sediaan"
            static let specimenInfo = "Informasi Sediaan"
            static let microscopicInterpretation = "Interpretasi Mikroskopis"
            static let bacteriaCountSuffix = " BTA"
            static let confidenceLevel = "Tingkat Keyakinan"
        }
        
        enum Confidence {
            static let perfect = "100% Confidence: Tidak ada keraguan dari sistem"
            static let high = "High Confidence: 90% - 99%"
            static let medium = "Medium Confidence: 70%-89%"
            static let low = "Low Confidence: 50%-69%"
            static let veryLow = "Very Low: 10% - 50%"
            static let unpredicted = "Unpredicted: 0% - 9%"
        }
    }
    
    // MARK: - Search & Filter (Reusable components)
    enum Search {
        static let placeholder = "Cari..."
        static let noResults = "Tidak ada hasil untuk"
        static let clearSearch = "Hapus Pencarian"
        static let searching = "Mencari..."
        
        enum Patient {
            static let placeholder = "Cari nama pasien"
        }
        
        enum Account {
            static let placeholder = "Cari akun"
        }
        
        static func noResults(_ searchTerm: String) -> String {
            return "Tidak ada hasil untuk \(searchTerm)"
        }
    }
    
    // MARK: - Forms (Reusable form elements)
    enum Form {
        static let optional = "(opsional)"
        static let selectOption = "Pilih opsi"
        static let enterValue = "Masukkan nilai"
        
        enum Validation {
            static let required = "Field ini wajib diisi"
            static let invalid = "Format tidak valid"
            static let tooShort = "Terlalu pendek"
            static let tooLong = "Terlalu panjang"
        }
        
        static func placeholder(_ fieldName: String) -> String {
            return "Masukkan \(fieldName)"
        }
        
        static func select(_ itemType: String) -> String {
            return "Pilih \(itemType)"
        }
        
        static func search(_ itemType: String) -> String {
            return "Cari \(itemType)"
        }
    }
    
    // MARK: - Navigation (Reusable navigation items)
    enum Navigation {
        static let profile = "Profil"
        static let history = "Riwayat"
        static let examination = "Pemeriksaan"
        static let patients = "Pasien"
        static let settings = "Pengaturan"
        static let accountManagement = "Manajemen Akun"
    }
    
    // MARK: - Common Data Patterns
    enum Data {
        static func count(_ number: Int, _ itemType: String) -> String {
            return "\(number) \(itemType)"
        }
        
        static func fromTo(_ current: Int, _ total: Int, _ itemType: String) -> String {
            return "\(current) dari \(total) \(itemType)"
        }
        
        static func imageCount(_ current: Int, _ total: Int) -> String {
            return "Gambar \(current) dari \(total)"
        }
    }
    
    enum Authentication {
        enum LoginView {
            static let title = "Revolusi Deteksi Bakteri dengan Teknologi AI"
            static let emailPlaceholder = "Contoh: nama.anda@gmail.com"
            static let passwordTitle = "Kata Sandi"
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
            static let currentPasswordPlaceholder = "Masukkan Kata Sandi"
            static let newPasswordTitle = "Kata Sandi Baru"
            static let newPasswordPlaceholder = "Masukkan Kata Sandi Baru"
            static let newPasswordDescription = "Kata sandi harus terdiri dari minimal 8 karakter"
            static let confirmPasswordTitle = "Konfirmasi Kata Sandi Baru"
            static let confirmPasswordPlaceholder = "Masukkan Konfirmasi Kata Sandi Baru"
        }

        enum UserAccessPinView {
            static let successTitle = "PIN Berhasil Diubah"
            static let successDescription = "PIN akses Anda telah berhasil diperbarui"
            static let successButton = "Kembali ke Profil"
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

    enum Examination {
        enum ProgressView {
            static let loadingAnimationName = "loadingPaperplane"
            static let analyzingTitle = "Menginterpretasikan data"
            static let refreshInstruction = "Tarik ke bawah untuk memuat ulang"
        }
        
        enum DetailViews {
            static let navigationTitle = "Detail Pemeriksaan"
            static let patientDataTitle = "Data Pasien"
            static let examinationResult1Title = "Hasil Pemeriksaan Sediaan 1"
            static let examinationResult2Title = "Hasil Pemeriksaan Sediaan 2"
            static let viewPdfButton = "Lihat PDF"
            static let reportToSitbButton = "Laporkan ke SITB"
            
            // New examination view specific strings
            static let newExaminationTitle = "Pemeriksaan Baru"
            static let dataPemeriksaanStep = "Data Pemeriksaan"
            static let hasilPemeriksaanStep = "Hasil Pemeriksaan"
            static let slideDetailTitle = "Detail Sediaan"
            static let slideImageTitle = "Gambar Sediaan"
        }
        
        enum GuidelinesOnboardingView {
            static let navigationTitle = "Persiapan Pemeriksaan"
            
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
                    title: "Pasang Smartphone pada Adapter",
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
            static let systemInterpretationWarning = "Interpretasi sistem bukan merupakan hasil akhir untuk pasien"
        }
        
        enum ConfirmationPopupsComponent {
            static let unfinishedExaminationTitle = "Pemeriksaan Belum Selesai"
            static let unfinishedExaminationDescription = "Pemeriksaan disimpan sebagai draft dan dapat diakses di halaman riwayat"
            static let reviewAgainButton = "Periksa Kembali"
            static let saveResultTitle = "Simpan Hasil Pemeriksaan"
            static let saveResultDescription = "Hasil pemeriksaan yang sudah disimpan tidak dapat diubah kembali"
        }
        
        enum GradingCardComponent {
            // This component doesn't have hardcoded strings, but keeping for consistency
        }
        
        enum ImageSectionComponent {
            static let imageResultTitle = "Hasil Gambar"
            static let imageResultInstruction = "Ketuk untuk lihat detail gambar"
        }
        
        enum InterpretationSectionComponent {
            static let selectCategoryPlaceholder = "Pilih kategori"
            static let btaCountPlaceholder = "Contoh: 8"
            static let staffMARKsPlaceholder = "Contoh: Hanya terdapat 20 bakteri dari 60 lapangan pandang yang terkumpul"
        }
        
        enum LaborantInfoComponent {
            static let examinationOfficerTitle = "Petugas Pemeriksaan"
            static let assignedByTitle = "Ditugaskan Oleh"
        }
        
        enum FolderCardComponent {
            // This component doesn't have hardcoded strings, but keeping for consistency
        }
        
        enum HeaderViewComponent {
            static let newExaminationTitle = "Pemeriksaan Baru"
        }
        
        enum ExtendableCardComponent {
            // This component doesn't have hardcoded strings, but keeping for consistency
        }
    }
    
    enum HomeHistory {
        static let loadingMessage = "Memuat data pemeriksaan anda"
        static let noExaminationMessage = "Tidak ada pemeriksaan diselesaikan pada"

        static let navigationTitleHome = "Tugas Pemeriksaan"
        static let taskSectionTitle = "Tugas Pemeriksaan"
        static let newExaminationButton = "Pemeriksaan Baru"
        static let noTaskMessage = "Anda belum ditugaskan untuk melakukan pemeriksaan"
        
        enum FinishedExaminationCardComponent {
            static let dpjpLabel = "DPJP"
            static let positiveKeyword = "positif"
            static let positiveAltKeyword = "positif"
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
            static let selectDatePickerTitle = "Pilih Tanggal"
        }
        
        enum HomeActivityComponent {
            static let examinationOfficerLabel = "Petugas Pemeriksaan"
        }
        
        enum ButtonActivityComponent {
            // This component doesn't have hardcoded strings, but keeping for consistency
        }
        
        enum HalfCircleProgressComponent {
            // This component doesn't have hardcoded strings, but keeping for consistency
        }
    }
    
    enum Patient {
        enum FormView {
            static let newPatientNavigationTitle = "Data Pasien Baru"
            static let editPatientNavigationTitle = "Ubah Data Pasien"
            static let addNewPatientButton = "Tambahkan Pasien Baru"
            static let savePatientButton = "Simpan Data Pasien"
        }
        
        enum ListView {
            static let addNewPatientButton = "Tambah Pasien Baru"
        }
        
        enum DetailView {
            static let navigationTitle = "Riwayat Pemeriksaan"
            static let patientDataTitle = "Data Pasien"
            static let newExaminationButton = "Pemeriksaan Baru"
            static let loadingPatientMessage = "Memuat data pasien..."
            static let loadingExaminationsMessage = "Memuat pemeriksaan..."
            static let noExaminationsMessage = "Belum ada pemeriksaan"
            static let notDeterminedMessage = "Belum ditentukan"
        }
        
        enum PatientCardComponent {
            static let birthDatePrefix = "Tanggal Lahir: "
        }
        
        enum PatientCardComponent {
            static let birthDatePrefix = "Tanggal Lahir: "
        }
        
        enum PatientFormFieldComponent {
            static let namePlaceholder = "John Doe"
        }
    }
    
    enum UserManagement {
        enum UserManagementView {
            static let addNewAccountButton = "Tambah Akun Baru"
            static let deleteAccountTitle = "Hapus akun"
            static let deleteAccountDescription = "Akun yang sudah dihapus tidak dapat dikembalikan lagi."
            static let deleteAccountButton = "Hapus Akun"
            static let deleteSuccessTitle = "Berhasil Menghapus Akun"
            static let deleteSuccessDescription = "Akun berhasil dihapus"
            static let deletionFailedTitle = "Gagal Menghapus"
        }
        
        enum NewUserFormView {
            static let navigationTitle = "Buat Akun Baru"
            static let successTitle = "Berhasil membuat Akun"
            static let successDescriptionPrefix = "Anda telah berhasil menambahkan akun baru untuk"
            static let successDescriptionSuffix = "dengan role"
            static let createAnotherAccountButton = "Buat Akun Lain"
            static let backToAccountListButton = "Kembali ke Daftar Akun"
            static let roleLabPlaceholder = "Laboran"
            static let roleAdminChoice = "Admin"
            static let namePlaceholder = "John Doe"
            static let emailPlaceholder = "john@gmail.com"
            static let registerAccountButton = "Daftarkan Akun"
            static let registrationFailedTitle = "Pendaftaran Gagal"
        }
        
        enum EditUserFormView {
            static let navigationTitle = "Edit Akun"
            static let successTitle = "Berhasil mengubah Akun"
            static let successDescriptionPrefix = "Anda telah berhasil mengubah akun untuk"
            static let successDescriptionSuffix = "dengan role"
            static let backToAccountListButton = "Kembali ke Daftar Akun"
            static let namePlaceholder = "Masukkan nama"
            static let emailDisabledDescription = "Email tidak dapat diubah"
            static let editFailedTitle = "Gagal Mengubah"
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
            static let cameraAccessDeniedTitle = "Akses Kamera Ditolak"
            static let cameraAccessDeniedMessage = "Silakan aktifkan akses kamera untuk Oculab di Pengaturan untuk merekam video"
            static let goToSettingsButton = "Buka Pengaturan"
        }
        
        enum InstructionRecordView {
            static let navigationTitle = "Instruksi Pemeriksaan"
            static let preparationSectionTitle = "Persiapan Pemeriksaan"
            static let recordingSectionTitle = "Instruksi Pengambilan Gambar"
            static let startRecordingButton = "Mulai Pengambilan Gambar"
        }
        
        enum StitchedImageView {
            static let navigationTitle = "Gambar Stitched"
            static let noImageAvailableMessage = "Tidak ada gambar yang tersedia"
        }
        
        enum FullScreenVideoPlayerView {
            // Empty enum for consistency, no specific strings needed
        }
        
        enum CameraViewComponent {
            static let cameraAccessAlertTitle = "Akses Kamera"
            static let cameraAccessAlertMessage = "Silakan aktifkan akses kamera dan mikrofon di pengaturan"
        }
        
        enum VideoPreviewComponent {
            static let saveVideoButton = "Simpan Video"
            static let retakeVideoButton = "Ambil Ulang"
        }
        
        enum VideoInputComponent {
            static let takeVideoButton = "Ambil Gambar"
            static let previewVideoButton = "Pratinjau Video"
            static let videoErrorAlertTitle = "Gagal Memutar Video"
            static let videoErrorAlertMessage = "Video tidak dapat diputar. Silakan rekam ulang sampel."
        }
    }
    
    enum TaskAssignment {
        enum InputPatientDataView {
            static let stepTitles = ["Data Pasien", "Data Sediaan", "Hasil"]
            static let currentStepIndex = 0
            static let picTitle = "Petugas Pemeriksaan"
            static let picPlaceholder = "Pilih Petugas"
            static let patientNamePlaceholder = "Cari nama pasien"
            static let patientNamePlaceholderAutoSelected = "Pasien dipilih otomatis"
            static let patientNameDescription = "Pilih atau masukkan data pasien baru"
            static let patientNameDescriptionAutoSelected = "Pasien telah dipilih dari riwayat"
            static let fillSpecimenDetailsButton = "Isi Detail Sediaan"
        }
        
        enum InputExaminationDataView {
            static let stepTitles = ["Data Pasien", "Data Sediaan", "Hasil"]
            static let currentStepIndex = 1
            static let confirmPopupTitle = "Buat Tugas Pemeriksaan?"
            static let createTaskButton = "Buat Tugas"
            static let reviewAgainButton = "Periksa Kembali"
            static let screeningChoice = "Skrinning"
            static let followUpChoice = "Follow Up"
            static let slideId1Title = "ID Sediaan 1"
            static let slideId1Placeholder = "Contoh: 24/11/1/0123A"
            static let slideType1Title = "Jenis Sediaan 1"
            static let slideId2Title = "ID Sediaan 2"
            static let slideId2Placeholder = "Contoh: 24/11/1/0123A"
            static let slideType2Title = "Jenis Sediaan 2"
            static let morningChoice = "Pagi"
            static let anytimeChoice = "Sewaktu"
            static let createTaskFinalButton = "Buat Tugas"
        }
        
        enum DateFieldComponent {
            // This component is mostly UI interaction based, no specific text constants needed
        }
        
        enum PatientDisplayFieldComponent {
            // This component is mostly UI interaction based, no specific text constants needed
        }
    }
    
    enum Analysist {
        enum AnalysisResultView {
            static let stepTitles = ["Data Pemeriksaan", "Hasil Pemeriksaan"]
            static let currentStepIndex = 1
            static let loadingExaminationMessage = "Loading examination data..."
        }
        
        enum InformationPageView {
            static let navigationTitle = "Informasi Interpretasi Sistem"
            static let assessmentStandardTitle = "Standar Penilaian"
            static let assessmentStandardDescription = "Sistem ini menghitung bakteri sesuai rekomendasi WHO dan standar IUALTD"
        }
        
        enum FOVDetailView {
            static let loadingDataMessage = "Memuat data pemeriksaan..."
            static let bacteriaCountPrefix = "Jumlah Bakteri: "
            static let slideIdPrefix = "ID "
        }
        
        enum PDFView {
            static let loadingAnimationName = "loadingPaperplane"
            static let downloadingDataMessage = "Mendownload data"
            static let examinationIdLabel = "ID Pemeriksaan"
            static let takenAtLabel = "Diambil di"
            static let officerLabel = "Petugas"
            static let noMARKsDefault = "Tidak ada catatan"
            static let reportingHeaderTitle = "Pelaporan"
            static let observationResultsHeaderTitle = "Hasil Pengamatan"
            
            // Table Content
            static let bacteriologicalExaminationResultTitle = "HASIL PEMERIKSAAN BAKTERIOLOGIS"
            static let testTypeLabel = "Jenis Uji"
            
            // Signature Section
            static let labOfficerSignatureTitle = "Petugas Lab"
            static let supervisingDoctorSignatureTitle = "Dokter PJ Pemeriksaan Lab"
        }
        
        enum FOVAlbumView {
            static let navigationTitleFormat = "Album Gambar %@"
        }
        
        enum ZoomableImageComponent {
            // This component is mostly UI interaction based, no specific text constants needed
        }
    }
}