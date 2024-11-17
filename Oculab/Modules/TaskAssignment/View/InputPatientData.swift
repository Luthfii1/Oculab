//
//  InputPatientData.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 07/11/24.
//

import SwiftUI

struct InputPatientData: View {
    @ObservedObject var presenter = InputPatientPresenter()
    @FocusState private var focusedField: FormField?

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
                            placeholder: "Cari nama pasien",
                            leftIcon: "person.fill",
                            rightIcon: "",
                            choices: presenter.patientNameDoB,
                            description: "Pilih atau masukkan data pasien baru",
                            selectedChoice: $presenter.selectedPatient,
                            isEnablingAdding: true
                        )
                        .focused($focusedField, equals: .search)

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
                }
            }
            .onChange(of: presenter.selectedPatient) { _, newValue in
                Task {
                    print(presenter.selectedPatient)
                    await presenter.getPatientById(patientId: newValue)
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

#Preview {
    InputPatientData()
}
