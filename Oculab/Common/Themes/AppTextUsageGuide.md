# AppText Usage Guide - Updated Structure

## ✅ Fixed Issues in AppText.swift

### 1. **Fixed Typos and Inconsistencies:**

- ✅ `Label.MARKs` → `Label.notes`
- ✅ `staffMARKsPlaceholder` → `staffNotesPlaceholder`
- ✅ `noMARKsDefault` → `noNotesDefault`
- ✅ Removed duplicate `PatientCardComponent`

### 2. **Updated to Use Universal Components:**

- ✅ Authentication fields now reference `AppLabel.*`
- ✅ Patient data fields reference `AppPatient.*`
- ✅ Form placeholders reference `AppForm.*`
- ✅ Actions reference `AppAction.*`

## 🎯 **How to Use the New Structure**

### **Universal Components (Use These First):**

```swift
// Patient Data
Text(AppPatient.name)              // "Nama"
Text(AppPatient.nik)               // "NIK"
Text(AppPatient.dateOfBirth)       // "Tanggal Lahir"
Text(AppPatient.gender)            // "Jenis Kelamin"
Text(AppPatient.bpjsNumber)        // "Nomor BPJS"

// Actions
Text(AppAction.save)               // "Simpan"
Text(AppAction.edit)               // "Ubah"
Text(AppAction.delete)             // "Hapus"
Text(AppAction.back)               // "Kembali"

// States
Text(AppState.loading)             // "Memuat..."
Text(AppState.notAvailable)        // "Belum Tersedia"
Text(AppState.success)             // "Berhasil"

// Labels
Text(AppLabel.email)               // "Email"
Text(AppLabel.password)            // "Kata Sandi"
Text(AppLabel.notes)               // "Catatan"
Text(AppLabel.role)                // "Role"

// Medical Terms
Text(AppMedical.BTA.negative)      // "Negatif"
Text(AppMedical.Examination.purpose) // "Tujuan Pemeriksaan"
Text(AppMedical.Examination.staffInterpretation) // "Interpretasi Petugas"

// Search
Text(AppSearch.Patient.placeholder) // "Cari nama pasien"
Text(AppSearch.clearSearch)        // "Hapus Pencarian"

// Navigation
Text(AppNav.profile)               // "Profil"
Text(AppNav.history)               // "Riwayat"
Text(AppNav.examination)           // "Pemeriksaan"
```

### **Dynamic Functions:**

```swift
// Dynamic Actions
Text(AppAction.save("Data Pasien"))     // "Simpan Data Pasien"
Text(AppAction.add("Akun Baru"))        // "Tambah Akun Baru"
Text(AppAction.edit("Profil"))          // "Ubah Profil"
Text(AppAction.backTo("Daftar Akun"))   // "Kembali ke Daftar Akun"
Text(AppAction.create("Tugas Baru"))    // "Buat Tugas Baru"
Text(AppAction.startAction("Pengambilan Gambar")) // "Mulai Pengambilan Gambar"

// Dynamic States
Text(AppState.loading("data pasien"))   // "Memuat data pasien..."
Text(AppState.success("menyimpan"))     // "Berhasil menyimpan"
Text(AppState.noData("pemeriksaan"))    // "Belum ada pemeriksaan"
Text(AppState.successWith("menghapus", "akun")) // "Berhasil menghapus akun"

// Dynamic Search
Text(AppSearch.noResults("John"))       // "Tidak ada hasil untuk John"

// Dynamic Form
Text(AppForm.placeholder("email"))      // "Masukkan email"
Text(AppForm.select("kategori"))        // "Pilih kategori"

// Dynamic Data Patterns
Text(AppData.count(5, "Gambar"))        // "5 Gambar"
Text(AppData.imageCount(1, 10))         // "Gambar 1 dari 10"
Text(AppData.albumTitle("Sediaan 1"))   // "Album Gambar Sediaan 1"
Text(AppData.resultTitle("Sediaan", 1)) // "Hasil Pemeriksaan Sediaan 1"
Text(AppData.slideIdTitle(1))           // "ID Sediaan 1"
Text(AppData.slideTypeTitle(2))         // "Jenis Sediaan 2"
Text(AppData.withPrefix("Jumlah:", "45")) // "Jumlah: 45"
```

### **Specific Module Texts (Only When Universal Components Don't Apply):**

```swift
// Only use these when universal components don't cover the use case
Text(AppTextAuthLogin.title)                    // "Revolusi Deteksi Bakteri..."
Text(AppTextExamGuidelines.navigationTitle)     // "Persiapan Pemeriksaan"
Text(AppTextVideoRecord.cameraAccessDeniedTitle) // "Akses Kamera Ditolak"
```

## 🔄 **Migration Examples:**

### **Before (Old Way):**

```swift
Text(AppTextPatientFormField.nameTitle)         // "Nama"
Text(AppTextExamDetail.patientNameKey)          // "Nama"
Text(AppTextPatientDetail.patientNameKey)       // "Nama"
Text(AppTextAnalysisPDF.nikLabel)               // "NIK"
Text(AppTextUserMgmtNewUserForm.emailTitle)     // "Email"
```

### **After (New Way):**

```swift
Text(AppPatient.name)                           // "Nama" (single source)
Text(AppPatient.nik)                            // "NIK" (single source)
Text(AppLabel.email)                            // "Email" (single source)
Text(AppData.slideIdTitle(1))                   // "ID Sediaan 1" (dynamic)
Text(AppState.loading("data pasien"))           // "Memuat data pasien..." (dynamic)
Text(AppAction.backTo("Profil"))                // "Kembali ke Profil" (dynamic)
```

## 🎨 **Best Practices:**

1. **Always check universal components first** before using module-specific texts
2. **Use dynamic functions** for patterns like "Simpan [ItemType]", "ID Sediaan [Number]"
3. **Prefer shorter typealiases** like `AppPatient` over `AppText.PatientData`
4. **Use comments** to indicate where universal components should be used
5. **Keep module-specific texts** only for truly unique content
6. **Leverage templatable patterns** for repetitive structures like slide numbers, result titles

## 📊 **Benefits Achieved:**

✅ **~200+ eliminated duplications** (increased from ~150+)  
✅ **Single source of truth** for common strings  
✅ **Better maintainability** - change once, update everywhere  
✅ **Type safety** with hierarchical structure  
✅ **Backward compatibility** maintained through typealiases  
✅ **Consistent naming** across the entire app  
✅ **Highly templatable** with dynamic functions for patterns  
✅ **Reduced hardcoded repetition** for slide numbers, result titles, etc.

## 🔮 **Next Steps:**

1. **Gradually migrate existing views** to use universal components
2. **Remove module-specific duplicates** as they're replaced
3. **Add localization support** to universal components first
4. **Update documentation** as more patterns emerge

---

**Remember:** The goal is to use universal components (`AppPatient.*`, `AppAction.*`, etc.) as much as possible, and only fall back to module-specific texts when absolutely necessary!
