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
                            PatientFormField(
                                isAddingNewPatient: isAddingNewPatient,
                                isAddingName: false,
                                presenter: presenter
                            )
                            AppButton(
                                title: "Isi Detail Sediaan",
                                rightIcon: "arrow.forward",
                                isEnabled: !(presenter.patient.NIK == "")
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
        }.navigationBarBackButtonHidden(true)
    }
}

#Preview {
    InputPatientData()
}
