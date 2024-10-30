//
//  ExamDataView.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import SwiftUI

struct ExamDataView: View {
    @StateObject private var videoRecordPresenter = VideoRecordPresenter.shared

    @StateObject var presenter = ExamDataPresenter(interactor: ExamInteractor())
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack(spacing: Decimal.d24) {
                AppStepper(
                    stepTitles: ["Data Pasien", "Data Sediaan", "Hasil"],
                    currentStep: 1
                ).padding(.top, Decimal.d12)

                ScrollView {
                    VStack(alignment: .leading, spacing: Decimal.d24) {
                        AppRadioButton(
                            title: "Tujuan Pemeriksaan",
                            isRequired: true,
                            choices: ["Skrinning", "Follow Up"],
                            selectedChoice: $presenter.examData.goal
                        )
                        AppRadioButton(
                            title: "Jenis Sediaan",
                            isRequired: true,
                            choices: ["Pagi", "Sewaktu"],
                            selectedChoice: $presenter.examData.preparationType
                        )
                        AppTextField(
                            title: "ID Sediaan",
                            isRequired: true,
                            placeholder: "Contoh: 24/11/1/0123A",
                            text: $presenter.examData.slideId
                        )
                        AppFileInput(
                            title: "Gambar Sediaan",
                            isRequired: true,
                            isEmpty: false,
                            selectedURL: $presenter.examData.recordVideo
                        ).environmentObject(presenter)
                    }
                }

                HStack {
                    AppButton(
                        title: "Kembali",
                        leftIcon: "arrow.left",
                        colorType: .tertiary,
                        isEnabled: true
                    ) {
                        print("Kembali Tapped")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(width: UIScreen.main.bounds.width / 3.5)

                    Spacer()
                    AppButton(
                        title: "Mulai Analisis",
                        rightIcon: "arrow.right",
                        size: .large,
                        isEnabled: presenter.examData.slideId != "" && presenter.examData
                            .recordVideo != nil && presenter.examData.goal != "" && presenter.examData
                            .preparationType != ""

                    ) {
                        presenter.handleSubmit()
                    }
                    .frame(maxWidth: .infinity)
                }

            }.padding(.horizontal, Decimal.d20)
                .navigationTitle("Pemeriksaan Baru")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image("back")
                            }
                        }
                    }
                }
        }.navigationBarBackButtonHidden(true)
            .onChange(of: videoRecordPresenter.previewURL) {
                presenter.examData.recordVideo = videoRecordPresenter.previewURL
            }
    }
}

#Preview {
    ExamDataView()
}
