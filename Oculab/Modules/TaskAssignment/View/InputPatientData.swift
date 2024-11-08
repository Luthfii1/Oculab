//
//  InputPatientData.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 07/11/24.
//

import SwiftUI

struct InputPatientData: View {
    @ObservedObject var presenter = InputPatientPresenter()

    @State var selectedPIC: String = ""
    @State var selectedPatient: String = ""

    @State var isAddingNewPatient: Bool = false

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack {
                    Spacer().frame(height: Decimal.d24)

                    AppStepper(stepTitles: ["Data Pasien", "Data Sediaan", "Hasil"], currentStep: 0)
                    Spacer().frame(height: Decimal.d24)

                    VStack(alignment: .leading, spacing: Decimal.d24) {
                        AppDropdown(
                            title: "Petugas Pemeriksaan",
                            placeholder: "Pilih Petugas",
                            leftIcon: "person.fill",
                            choices: presenter.picName,
                            selectedChoice: $selectedPIC,
                            isAddingNewPatient: .constant(true)
                        )

                        AppDropdown(
                            title: "Nama",
                            placeholder: "Cari nama pasien",
                            leftIcon: "person.fill",
                            rightIcon: "",
                            choices: presenter.patientNameDoB,
                            description: "Pilih atau masukkan data pasien baru",
                            selectedChoice: $selectedPatient,
                            isEnablingAdding: true,
                            isAddingNewPatient: $isAddingNewPatient
                        )

                        if selectedPatient != "" {
                            AppTextField(
                                title: "NIK",
                                placeholder: "Contoh: 167012039484700",
                                isDisabled: !isAddingNewPatient,
                                text: $presenter.patient.NIK
                            )

                            DateField(
                                title: "Tanggal Lahir",
                                placeholder: "Pilih Tanggal",
                                rightIcon: "calendar",
                                isDisabled: !isAddingNewPatient,
                                date: Binding(
                                    get: { presenter.patient.DoB ?? Date() },
                                    set: { presenter.patient.DoB = $0 }
                                )
                            )

                            AppRadioButton(
                                title: "Jenis Kelamin", isRequired: true,
                                choices: ["Perempuan", "Laki-laki"],
                                selectedChoice: Binding(
                                    get: { presenter.patient.sex.rawValue },
                                    set: { presenter.patient.sex = SexType(rawValue: $0) ?? .MALE }
                                )
                            )

                            AppTextField(
                                title: "Nomor BPJS (opsional)",
                                placeholder: "Contoh: 06L30077675",
                                isDisabled: !isAddingNewPatient,
                                text: Binding(
                                    get: { presenter.patient.BPJS ?? "" },
                                    set: { presenter.patient.BPJS = $0.isEmpty ? nil : $0 }
                                )
                            )

                            AppButton(
                                title: "Isi Detail Sediaan",
                                rightIcon: "arrow.forward",
                                isEnabled: !(presenter.patient.NIK == "")
                            ) {
                                presenter.newExam(patientId: selectedPatient, picId: selectedPIC)
                            }

                            Spacer()
                        }
                    }

                    .padding(.horizontal, Decimal.d20)
                }

                .navigationTitle("Pemeriksaan")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            //                        presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image("Destroy")
                            }
                        }
                    }
                }
            }
            .onAppear {
                presenter.getAllUser()
                presenter.getAllPatient()
            }
            .onChange(of: selectedPatient) { newValue in
                if !newValue.isEmpty {
                    presenter.getPatientById(patientId: newValue)
                }
            }
            .onChange(of: selectedPIC) { newValue in
                if !newValue.isEmpty {
                    presenter.getUserById(userId: newValue)
                }
            }
        }
    }
}

#Preview {
    InputPatientData()
}
