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
typealias AppFeature = AppText.Feature

enum AppText {
    // MARK: - Core System Icons (Reusable across all modules)
    enum SystemIcon {
        static let back = "chevron.left"
        static let forward = "chevron.right"
        static let up = "chevron.up"
        static let down = "chevron.down"
        static let backCircle = "chevron.backward.circle"
        static let close = "xmark"
        static let add = "plus"
        static let edit = "pencil"
        static let delete = "trash"
        static let search = "magnifyingglass"
        static let settings = "gearshape"
        static let info = "info.circle"
        static let warning = "exclamationmark.triangle.fill"
        static let alert = "exclamationmark.circle.fill"
        static let success = "checkmark.circle.fill"
        static let error = "xmark.circle.fill"
        static let circleFill = "circle.fill"
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
        static let eyeSlash = "eye.slash"
        static let faceId = "faceid"
        static let checkmark = "checkmark"
        static let personFill = "person.fill"
        static let arrowRight = "arrow.right"
        static let arrowForward = "arrow.forward"
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
        static let rectangleSplit2x2Fill = "rectangle.split.2x2.fill"
        static let clockArrowCirclepath = "clock.arrow.circlepath"
        static let clockFill = "clock.fill"
        static let personCircle = "person.circle"
        static let squareAndPencil = "square.and.pencil"
        static let circle = "circle"
        static let largecircleFillCircle = "largecircle.fill.circle"
        static let buttonProgrammable = "button.programmable"
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
        static let robot = "robot"
        static let instruction = "Instruction"
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
        static let confirm = "Konfirmasi"
        static let search = "Cari"
        
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
        
        static func add(_ itemType: String?) -> String {
            return "Tambah \(String(describing: itemType))"
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
        
        static func backTo(_ destination: String) -> String {
            return "Kembali ke \(destination)"
        }
        
        static func startAction(_ actionType: String) -> String {
            return "Mulai \(actionType)"
        }
        
        static func create(_ itemType: String) -> String {
            return "Buat \(itemType)"
        }
        
        static func disable(_ itemType: String) -> String {
            return "Nonaktifkan \(itemType)"
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
        
        static func noData(_ itemType: String) -> String {
            return "Belum ada \(itemType)"
        }
        
        static func notDetermined(_ itemType: String) -> String {
            return "\(itemType) belum ditentukan"
        }
        
        static func successWith(_ action: String, _ itemType: String) -> String {
            return "Berhasil \(action) \(itemType)"
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
        static let notes = "Catatan"
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
            static let other = "Lainnya"
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
        static let patient = "Pasien"
        
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
            static let examinationId = "ID Pemeriksaan" 
            static let specimenType = "Jenis Sediaan"
            static let specimenInfo = "Informasi Sediaan"
            static let microscopicInterpretation = "Interpretasi Mikroskopis"
            static let bacteriaCountSuffix = " BTA"
            static let confidenceLevel = "Tingkat Keyakinan"
            static let goalScreening = "Skrining"
            static let goalFollowUp = "Follow Up"
            static let preparationTypeAnytime = "Sewaktu"
            static let preparationTypeMorning = "Pagi"
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
        static let search = "Cari"
        static let placeholder = "Cari..."
        static let noResults = "Tidak ada data yang sesuai"
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
        
        static func resultFor(_ itemType: String) -> String {
            return "\"\(itemType)\""
        }
    }
    
    // MARK: - Forms (Reusable form elements)
    enum Form {
        static let optional = "(opsional)"
        static let selectOption = "Pilih opsi"
        static let enterValue = "Masukkan nilai"
        static let disable = "Nonaktifkan"
        
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
        
        static func albumTitle(_ itemName: String) -> String {
            return "Album Gambar \(itemName)"
        }
        
        static func resultTitle(_ itemName: String, _ slideNumber: Int) -> String {
            return "Hasil Pemeriksaan \(itemName) \(slideNumber)"
        }
        
        static func slideTitle(_ slideNumber: Int) -> String {
            return "Sediaan \(slideNumber)"
        }
        
        static func slideIdTitle(_ slideNumber: Int) -> String {
            return "ID Sediaan \(slideNumber)"
        }

        static func slideIdPlaceholder(_ slideNumber: String) -> String {
            return "Contoh: \(slideNumber)"
        }
        
        static func slideTypeTitle(_ slideNumber: Int) -> String {
            return "Jenis Sediaan \(slideNumber)"
        }
        
        static func withPrefix(_ prefix: String, _ content: String) -> String {
            return "\(prefix) \(content)"
        }
        
        static func makeSentence<T>(_ words: [T]) -> String {
            guard !words.isEmpty else {
                return ""
            }
            
            var sentence = String(describing: words[0])
            
            for word in words.dropFirst() {
                sentence += " \(String(describing: word))"
            }
            
            return sentence
        }
    }
    
    enum Feature {
        static let radioButton = "Tombol Pilihan Radio"
    }
}
