//
//  SavedResultView.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import SwiftUI

struct SavedResultView: View {
    var examId: String
    var patientId: String

    @StateObject var presenter = ExamDataPresenter(interactor: ExamInteractor())
    @StateObject var resultPresenter = AnalysisResultPresenter()

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                Spacer().frame(height: Decimal.d24)

                VStack(alignment: .leading, spacing: Decimal.d24) {
                    ExtendableCard(
                        icon: "person.fill",
                        title: "Data Pasien",
                        isExtendable: true,
                        data: [
                            (key: "Nama", value: presenter.patientDetailData.name),
                            (key: "NIK", value: presenter.patientDetailData.nik),
                            (key: "Tanggal Lahir", value: presenter.patientDetailData.dob),
                            (key: "Jenis Kelamin", value: presenter.patientDetailData.sex),
                            (key: "Nomor BPJS", value: presenter.patientDetailData.bpjs),
                        ],
                        titleSize: AppTypography.s5
                    )

                    ExtendableCard(
                        icon: "doc.text.magnifyingglass",
                        title: "Detail Pemeriksaan",
                        isExtendable: true,
                        data: [
                            (key: "ID Sediaan", value: presenter.examDetailData.slideId),
                            (key: "Alasan Pemeriksaan", value: presenter.examDetailData.examinationGoal),
                            (key: "Jenis Sediaan", value: presenter.examDetailData.type),
                        ],
                        titleSize: AppTypography.s6
                    )

                    AppCard(icon: "photo", title: "Hasil Gambar", spacing: Decimal.d16) {
                        VStack(alignment: .leading, spacing: Decimal.d16) {
                            Text("Ketuk untuk lihat detail gambar")
                                .font(AppTypography.p3)
                                .foregroundStyle(AppColors.slate300)

                            RoundedRectangle(cornerRadius: Decimal.d8)
                                .foregroundStyle(AppColors.slate50)
                                .frame(height: 200)

                            if resultPresenter.groupedFOVs?.bta0.isEmpty != true {
                                Button {} label: {
                                    FolderCardComponent(
                                        title: .BTA0,
                                        numOfImage: resultPresenter.groupedFOVs?.bta0.count ?? 0
                                    )
                                }
                            }

                            if resultPresenter.groupedFOVs?.bta1to9.isEmpty != true {
                                Button {} label: {
                                    FolderCardComponent(
                                        title: .BTA1TO9,
                                        numOfImage: resultPresenter.groupedFOVs?.bta1to9.count ?? 0
                                    )
                                }
                            }

                            if resultPresenter.groupedFOVs?.btaabove9.isEmpty != true {
                                Button {} label: {
                                    FolderCardComponent(
                                        title: .BTAABOVE9,
                                        numOfImage: resultPresenter.groupedFOVs?.btaabove9.count ?? 0
                                    )
                                }
                            }
                        }
                    }

                    AppCard(icon: "text.badge.checkmark", title: "Hasil Interpretasi", spacing: Decimal.d24) {
                        VStack(alignment: .leading, spacing: Decimal.d8) {
                            Text("Interpretasi Petugas")
                                .font(AppTypography.s5)
                                .foregroundColor(AppColors.slate300)
                            GradingCardComponent(
                                type: .SCANTY,
                                confidenceLevel: .lowConfidence
                            )
                        }

                        VStack(alignment: .leading, spacing: Decimal.d8) {
                            Text("Interpretasi Sistem")
                                .font(AppTypography.s5)
                                .foregroundColor(AppColors.slate300)
                            HStack(alignment: .top) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(AppColors.orange500)

                                Text("Interpretasi sistem bukan merupakan hasil akhir untuk pasien")
                                    .font(AppTypography.p4)
                            }
                            GradingCardComponent(
                                type: .SCANTY,
                                confidenceLevel: .lowConfidence
                            )
                        }

                        VStack(alignment: .leading, spacing: Decimal.d16) {
                            AppButton(
                                title: "Lihat PDF",
                                rightIcon: "doc.text",
                                colorType: .secondary,
                                size: .small,
                                isEnabled: true
                            ) {
                                print("Lihat PDF Tapped")
                            }

                            AppButton(
                                title: "Laporkan ke SITB",
                                rightIcon: "paperplane",
                                size: .small,
                                isEnabled: true
                            ) {
                                print("Lihat PDF Tapped")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Decimal.d16)
            .navigationTitle(examId)
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
            .onAppear {
                Task {
                    await presenter.fetchData(examId: examId, patientId: patientId)
                    await resultPresenter.fetchData(examinationId: examId)
                }
            }
        }.navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SavedResultView(examId: "6f4e5288-3dfd-4be4-8a2e-8c60f09f07e2", patientId: "d0c1a2b3-4f5e-6789-91ab-cdef12345678")
}
