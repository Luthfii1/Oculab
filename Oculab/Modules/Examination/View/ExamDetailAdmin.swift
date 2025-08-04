//
//  ExamDetailAdmin.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 08/11/24.
//

import SwiftUI

struct ExamDetailAdmin: View {
    var examId: String
    var patientId: String

    @StateObject var presenter = ExamDataPresenter(interactor: ExamInteractor())
    @StateObject var resultPresenter = AnalysisResultPresenter()

    var body: some View {
        NavigationView {
            ScrollView {
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

                    LaborantInfoComponent(
                        pic: presenter.examDetailData.pic,
                        dpjp: presenter.examDetailData.dpjp
                    )

                    AppCard(
                        icon: "doc.text.magnifyingglass",
                        title: "Hasil Pemeriksaan Sediaan 1",
                        spacing: Decimal.d16
                    ) {
                        VStack(alignment: .leading) {
                            Text("Interpretasi Petugas")
                                .font(AppTypography.s5)
                                .foregroundColor(AppColors.slate300)
                                
                                let interpretasiPetugas = presenter.examinations.first?.expertResult ?? "Belum Tersedia"
                                
                                if interpretasiPetugas != "Belum Tersedia" {
                                    GradingCardComponent(
                                        type: GradingType(rawValue: interpretasiPetugas) ?? .unknown,
                                        confidenceLevel: .lowConfidence,
                                        isExpert: true
                                    )
                                } else {
                                    Text("Belum Tersedia")
                                        .font(AppTypography.p4)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(AppColors.slate50)
                                        .cornerRadius(20)
                                }
                        }
                        ExtendedCard(data: [
                            ("ID Sediaan", presenter.examinations.first?.slideId ?? ""),
                            ("Jenis Sediaan", presenter.examinations.first?.preparationType ?? "")
                        ], titleSize: AppTypography.s5)
                    }

                    AppCard(
                        icon: "doc.text.magnifyingglass",
                        title: "Hasil Pemeriksaan Sediaan 2",
                        spacing: Decimal.d16
                    ) {
                        VStack(alignment: .leading) {
                            Text("Interpretasi Petugas")
                                .font(AppTypography.s5)
                                .foregroundColor(AppColors.slate300)
                            
                            let interpretasiPetugas = presenter.examinations.count > 1 ? (presenter.examinations[1].expertResult ?? "Belum Tersedia") : "Belum Tersedia"
                            
                            if interpretasiPetugas != "Belum Tersedia" {
                                GradingCardComponent(
                                    type: GradingType(rawValue: interpretasiPetugas) ?? .unknown,
                                    confidenceLevel: .lowConfidence,
                                    isExpert: true
                                )
                            } else {
                                Text("Belum Tersedia")
                                    .font(AppTypography.p4)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(AppColors.slate50)
                                    .cornerRadius(20)
                            }
                        }
                        ExtendedCard(data: [
                            ("ID Sediaan", presenter.examinations.count > 1 ? presenter.examinations[1].slideId : ""),
                            ("Jenis Sediaan", presenter.examinations.count > 1 ? presenter.examinations[1].preparationType : "")
                        ], titleSize: AppTypography.s5)
                    }
                    VStack(spacing: Decimal.d16) {
                        AppButton(
                            title: "Lihat PDF",
                            rightIcon: "doc.text",
                            colorType: .secondary,
                            size: .small,
                            isEnabled: true
                        ) {
                            resultPresenter.navigateToPDFView()
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
            .padding(.horizontal, Decimal.d16)
            .navigationTitle("Detail Pemeriksaan")
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
                    await presenter.fetchData(examId: examId, patientId: patientId, userRole: .ADMIN)
                    await resultPresenter.fetchData(examinationId: examId)
                }
            }
        }.navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ExamDetailAdmin(examId: "6f4e5288-3dfd-4be4-8a2e-8c60f09f07e2", patientId: "d0c1a2b3-4f5e-6789-91ab-cdef12345678")
}
