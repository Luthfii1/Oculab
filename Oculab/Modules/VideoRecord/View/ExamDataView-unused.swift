////
////  ExamDataView-unused.swift
////  Oculab
////
////  Created by Alifiyah Ariandri on 16/10/24.
////
//
// import SwiftUI
//
// struct ExamDataView: View {
//    @StateObject private var videoRecordPresenter = VideoRecordPresenter.shared
//
//    @StateObject var presenter = ExamDataPresenter(interactor: ExamInteractor())
//    @Environment(\.presentationMode) var presentationMode
//
//    var body: some View {
//        NavigationView {
//            VStack(spacing: Decimal.d24) {
//                AppStepper(
//                    stepTitles: ["Data Pasien", "Data Sediaan", "Hasil"],
//                    currentStep: 1
//                ).padding(.top, Decimal.d12)
//
//                ScrollView {
//                    VStack(alignment: .leading, spacing: Decimal.d24) {
//                        AppRadioButton(
//                            title: "Tujuan Pemeriksaan",
//                            isRequired: true,
//                            choices: ["Skrinning", "Follow Up"],
//                            selectedChoice: $presenter.examData.examination.goal
//                        )
//                        AppRadioButton(
//                            title: "Jenis Sediaan",
//                            isRequired: true,
//                            choices: ["Pagi", "Sewaktu"],
//                            selectedChoice: $presenter.examData.examination.preparationType
//                        )
//                        AppTextField(
//                            title: "ID Sediaan",
//                            isRequired: true,
//                            placeholder: "Contoh: 24/11/1/0123A",
//                            text: $presenter.examData.examination.slideId
//                        )
//                        VideoInput(
//                            title: "Gambar Sediaan",
//                            isRequired: true,
//                            isEmpty: false,
//                            selectedURL: $presenter.examData.examination.recordVideo
//                        ).environmentObject(presenter)
//                    }
//                }
//
//                HStack {
//                    AppButton(
//                        title: "Kembali",
//                        leftIcon: "arrow.left",
//                        colorType: .tertiary,
//                        isEnabled: true
//                    ) {
//                        print("Kembali Tapped")
//                    }
//                    .frame(maxWidth: .infinity)
//                    .frame(width: UIScreen.main.bounds.width / 3.5)
//
//                    Spacer()
//                    AppButton(
//                        title: "Mulai Analisis",
//                        rightIcon: "arrow.right",
//                        size: .large,
//                        isEnabled: presenter.examData.examination.slideId != "" && presenter.examData.examination
//                            .recordVideo != nil && presenter.examData.examination.goal != "" && presenter.examData
//                            .examination
//                            .preparationType != ""
//
//                    ) {
//                        presenter.handleSubmit { result in
//                            switch result {
//                            case .success:
//                                print("Examination submitted successfully.")
//                            case let .failure(error):
//                                print("Failed to submit examination: \(error)")
//                            }
//                        }
//                    }
//                    .frame(maxWidth: .infinity)
//                }
//
//            }.padding(.horizontal, Decimal.d20)
//                .navigationTitle("Pemeriksaan Baru")
//                .navigationBarTitleDisplayMode(.inline)
//                .toolbar {
//                    ToolbarItem(placement: .navigationBarLeading) {
//                        Button(action: {
//                            presentationMode.wrappedValue.dismiss()
//                        }) {
//                            HStack {
//                                Image("back")
//                            }
//                        }
//                    }
//                }
//        }.navigationBarBackButtonHidden(true)
//            .onChange(of: videoRecordPresenter.previewURL) {
//                presenter.examData.examination.recordVideo = videoRecordPresenter.previewURL
//
//                print(presenter.examData)
//            }
//    }
// }
//
// #Preview {
//    ExamDataView()
// }
