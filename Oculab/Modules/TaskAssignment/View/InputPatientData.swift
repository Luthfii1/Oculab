//
//  InputPatientData.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 07/11/24.
//

import SwiftUI

struct InputPatientData: View {
    let patientId: String?
    @ObservedObject var presenter = InputPatientPresenter()
    @FocusState private var focusedField: FormField?
    
    init(patientId: String? = nil) {
        self.patientId = patientId
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack {
                    Spacer().frame(height: Decimal.d24)
                    AppStepper(stepTitles: ["Data Pasien", "Data Sediaan", "Hasil"], currentStep: 0)
                    Spacer().frame(height: Decimal.d24)
                    
                    VStack(alignment: .leading, spacing: Decimal.d24) {
                        // PIC Dropdown
                        AppDropdown(
                            title: "Petugas Pemeriksaan",
                            placeholder: "Pilih Petugas",
                            leftIcon: "person.fill",
                            choices: presenter.picName,
                            selectedChoice: $presenter.selectedPIC
                        )
                        
                        // Patient Search Dropdown
                        AppDropdown(
                            title: "Nama",
                            placeholder: patientId != nil ? "Pasien dipilih otomatis" : "Cari nama pasien",
                            leftIcon: "person.fill",
                            rightIcon: "",
                            choices: presenter.patientNameDoB,
                            description: patientId != nil ? "Pasien telah dipilih dari riwayat" : "Pilih atau masukkan data pasien baru",
                            selectedChoice: $presenter.selectedPatient,
                            isEnablingAdding: patientId == nil
                        )
                        .focused($focusedField, equals: .search)
                        .disabled(patientId != nil)
                        
                        if presenter.selectedPatient != "" {
                            PatientFormField(focusedField: _focusedField)
                                .environmentObject(presenter)
                            
                            AppButton(
                                title: "Isi Detail Sediaan",
                                rightIcon: "arrow.forward",
                                isEnabled: !(presenter.patient.NIK == "" || presenter.patient.DoB == nil)
                            ) {
                                presenter.newExam()
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, Decimal.d20)
                }
                .navigationTitle("Pemeriksaan")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            Router.shared.navigateBack()
                        }) {
                            HStack {
                                Image("Destroy")
                            }
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await presenter.getAllUser()
                    await presenter.getAllPatient()
                    
                    // Auto-fill patient if patientId is provided
                    if let patientId = patientId, !patientId.isEmpty {
                        await presenter.getPatientById(patientId: patientId)
                        // Set the selected patient to trigger the form display
                        presenter.selectedPatient = patientId
                    }
                }
            }
            .onChange(of: presenter.selectedPatient) { _, newValue in
                Task {
                    print(presenter.selectedPatient)
                    // Only fetch if it's not already auto-filled
                    if patientId == nil || newValue != patientId {
                        await presenter.getPatientById(patientId: newValue)
                    }
                }
            }
            .onChange(of: presenter.selectedPIC) { _, newValue in
                if !newValue.isEmpty {
                    Task {
                        await presenter.getUserById(userId: newValue)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview("With Patient") {
    InputPatientData(patientId: "d0c1a2b3-4f5e-6789-91ab-cdef12345678")
}

