//
//  InputExaminationData.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 07/11/24.
//

import SwiftUI

struct InputExaminationData: View {
    @ObservedObject var presenter: InputPatientPresenter = .init()

    @State var selectedPIC: String
    @State var selectedPatient: String
    @State var goalString: String = ""
    @State var typeString: String = ""

    @State var typeString2: String = ""

    @State var isAddingNewPatient: Bool = false

    @State var isSubmitPopUpVisible: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                AppPopup(
                    image: "Confirm",
                    title: "Buat Tugas Pemeriksaan?",
                    description: "Sediaan Pasien \(presenter.patient.name) akan diperiksa oleh \(presenter.pic.name)",
                    buttons: [
                        AppButton(
                            title: "Buat Tugas",
                            colorType: .primary,
                            size: .large,
                            isEnabled: true
                        ) {
                            Task {
                                await presenter.submitExamination()
                            }
                        },

                        AppButton(
                            title: "Periksa Kembali",
                            colorType: .tertiary,
                            isEnabled: true
                        ) {
                            isSubmitPopUpVisible = false
                            print("Kembali ke Pemeriksaan")
                        }
                    ],
                    isVisible: $isSubmitPopUpVisible
                )

                VStack {
                    ScrollView(showsIndicators: false) {
                        VStack {
                            Spacer().frame(height: Decimal.d24)

                            AppStepper(stepTitles: ["Data Pasien", "Data Sediaan", "Hasil"], currentStep: 1)
                            Spacer().frame(height: Decimal.d24)

                            VStack(alignment: .leading, spacing: Decimal.d24) {
                                AppRadioButton(
                                    title: "Tujuan Pemeriksaan",
                                    isRequired: true,
                                    choices: ["Skrinning", "Follow Up"],
                                    isDisabled: false,
                                    selectedChoice: $goalString
                                ).onChange(of: goalString) {
                                    switch goalString {
                                    case "Skrining":
                                        presenter.examination.goal = .SCREENING
                                        presenter.examination2.goal = .SCREENING

                                    case "Follow Up":
                                        presenter.examination.goal = .TREATMENT
                                        presenter.examination2.goal = .TREATMENT

                                    default:
                                        presenter.examination.goal = .SCREENING
                                        presenter.examination2.goal = .SCREENING
                                    }
                                }

                                AppTextField(
                                    title: "ID Sediaan 1",
                                    placeholder: "Contoh: 24/11/1/0123A",
                                    text: $presenter.examination.slideId
                                )

                                AppRadioButton(
                                    title: "Jenis Sediaan 1",
                                    isRequired: true,
                                    choices: ["Pagi", "Sewaktu"],
                                    isDisabled: false,
                                    selectedChoice: $typeString
                                ).onChange(of: typeString) {
                                    switch typeString {
                                    case "Pagi":
                                        presenter.examination.preparationType = .SP
                                    case "Sewaktu":
                                        presenter.examination.preparationType = .SPS
                                    default:
                                        presenter.examination.preparationType = .SPS
                                    }
                                }

                                AppTextField(
                                    title: "ID Sediaan 2",
                                    placeholder: "Contoh: 24/11/1/0123A",
                                    text: $presenter.examination2.slideId
                                )

                                AppRadioButton(
                                    title: "Jenis Sediaan 2",
                                    isRequired: true,
                                    choices: ["Pagi", "Sewaktu"],
                                    isDisabled: false,
                                    selectedChoice: $typeString2
                                ).onChange(of: typeString2) {
                                    switch typeString2 {
                                    case "Pagi":
                                        presenter.examination2.preparationType = .SP
                                    case "Sewaktu":
                                        presenter.examination2.preparationType = .SPS
                                    default:
                                        presenter.examination2.preparationType = .SPS
                                    }
                                }
                            }

                            .padding(.horizontal, Decimal.d20)
                        }

                        .navigationTitle("Pemeriksaan")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    Router.shared.popToRoot()
                                }) {
                                    HStack {
                                        Image("Destroy")
                                    }
                                }
                            }
                        }
                    }

                    HStack {
                        AppButton(
                            title: "Kembali",
                            leftIcon: "arrow.left",
                            colorType: .tertiary,
                            isEnabled: true
                        ) {
                            Router.shared.navigateBack()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(width: UIScreen.main.bounds.width / 3.5)

                        Spacer()
                        AppButton(
                            title: "Buat Tugas",
                            rightIcon: "arrow.right",
                            size: .large,
                            isEnabled: true
                        ) {
                            isSubmitPopUpVisible = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, Decimal.d20)
                }
            }
            .onAppear {
                Task {
                    await presenter.getPatientById(patientId: selectedPatient)
                    print(selectedPatient)
                    print(presenter.patient.name)
                    await presenter.getUserById(userId: selectedPIC)

                    print(presenter.patient.name)
                }
            }
        }.navigationBarBackButtonHidden(true)
    }
}

#Preview {
    InputExaminationData(selectedPIC: "", selectedPatient: "")
}
