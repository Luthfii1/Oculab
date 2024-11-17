//
//  ExamDetailView.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 30/10/24.
//

import SwiftUI

struct ExamDetailView: View {
    var examId: String
    var patientId: String

    @StateObject private var videoRecordPresenter = VideoRecordPresenter.shared
    @StateObject var presenter = ExamDataPresenter(interactor: ExamInteractor())
//    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                AppStepper(
                    stepTitles: ["Data Pemeriksaan", "Hasil Pemeriksaan"],
                    currentStep: 0
                ).padding(.top, Decimal.d12)

                Spacer().frame(height: Decimal.d24)

                VStack(spacing: Decimal.d24) {
                    if presenter.isLoading == true {
                        ProgressView()
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LaborantInfoComponent(
                                pic: presenter.examDetailData.pic,
                                dpjp: presenter.examDetailData.dpjp
                            )

                            AppCard(
                                icon: "person.fill",
                                title: "Data Pasien",
                                spacing: Decimal.d8,
                                isBorderDisabled: true
                            ) {
                                ExtendedCard(data: [
                                    (key: "Nama", value: presenter.patientDetailData.name),
                                    (key: "NIK", value: presenter.patientDetailData.nik),
                                    (key: "Tanggal Lahir", value: presenter.patientDetailData.dob),
                                    (key: "Jenis Kelamin", value: presenter.patientDetailData.sex),
                                    (key: "Nomor BPJS", value: presenter.patientDetailData.bpjs)
                                ], titleSize: AppTypography.s5)
                            }

                            AppCard(
                                icon: "doc.text.magnifyingglass",
                                title: "Detail Sediaan",
                                spacing: Decimal.d8,
                                isBorderDisabled: true
                            ) {
                                ExtendedCard(data: [
                                    (key: "ID Sediaan", value: presenter.examDetailData.slideId),
                                    (key: "Tujuan Pemeriksaan", value: presenter.examDetailData.examinationGoal),
                                    (key: "Jenis Sediaan", value: presenter.examDetailData.type)
                                ], titleSize: AppTypography.s5)
                            }

                            VideoInput(
                                title: "Gambar Sediaan",
                                isRequired: true,
                                isEmpty: false,
                                selectedURL: $presenter.recordVideo
                            ).environmentObject(presenter)

                            VStack(alignment: .leading, spacing: Decimal.d24) {}
                        }
                    }

                    AppButton(
                        title: "Mulai Analisis",
                        rightIcon: "arrow.right",
                        size: .large,
                        isEnabled: presenter.recordVideo != nil

                    ) {
                        Task {
                            await presenter.handleSubmit()
                            presenter.navigateToAnalysisResult(examinationId: presenter.examDetailData.examinationId)
                        }
                    }
                }
                .padding(.horizontal, Decimal.d20)
                .navigationTitle("Pemeriksaan Baru")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            Router.shared.navigateBack()
                        }) {
                            HStack {
                                Image("back")
                            }
                        }
                    }
                }
            }

        }.navigationBarBackButtonHidden(true)
            .onAppear {
                Task {
                    await presenter.fetchData(examId: examId, patientId: patientId)
                    print(presenter.isLoading)
                }
            }
            .onChange(of: videoRecordPresenter.previewURL) {
                presenter.recordVideo = videoRecordPresenter.previewURL
            }
    }
}

#Preview {
    ExamDetailView(examId: "6f4e5288-3dfd-4be4-8a2e-8c60f09f07e2", patientId: "f3g4h5i6-7891-abcd-ef12-3456789abcdef")
}
