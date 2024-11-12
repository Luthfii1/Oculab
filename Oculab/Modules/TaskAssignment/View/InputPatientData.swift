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
                            selectedChoice: $selectedPIC
                        )

                        AppDropdown(
                            title: "Nama",
                            placeholder: "Cari nama pasien",
                            leftIcon: "person.fill",
                            rightIcon: "",
                            choices: presenter.patientNameDoB,
                            description: "Pilih atau masukkan data pasien baru",
                            selectedChoice: $selectedPatient,
                            isEnablingAdding: true
                        )

                        if selectedPatient != "" {
                            PatientFormField(
                                isAddingName: presenter.patientFound,
                                presenter: presenter
                            )
                            AppButton(
                                title: "Isi Detail Sediaan",
                                rightIcon: "arrow.forward",
                                isEnabled: !(presenter.patient.NIK == "" || presenter.patient.DoB == nil)
                            ) {
//                                if !presenter.patientFound {
//                                    presenter.addNewPatient()
//                                }
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
            .onChange(of: selectedPatient) { _, newValue in
                print(selectedPatient)
                presenter.getPatientById(patientId: newValue)
            }
            .onChange(of: selectedPIC) { _, newValue in
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
