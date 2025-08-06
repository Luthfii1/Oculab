//
//  ExamDetailAdminView.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 08/11/24.
//

import SwiftUI

struct ExamDetailAdminView: View {
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
                        icon: AppText.Icon.personFill,
                        title: AppTextExamDetail.patientDataTitle,
                        isExtendable: true,
                        data: [
                            (key: AppTextExamDetail.patientNameKey, value: presenter.patientDetailData.name),
                            (key: AppTextExamDetail.patientNikKey, value: presenter.patientDetailData.nik),
                            (key: AppTextExamDetail.patientDobKey, value: presenter.patientDetailData.dob),
                            (key: AppTextExamDetail.patientSexKey, value: presenter.patientDetailData.sex),
                            (key: AppTextExamDetail.patientBpjsKey, value: presenter.patientDetailData.bpjs),
                        ],
                        titleSize: AppTypography.s5
                    )

                    LaborantInfoComponent(
                        pic: presenter.examDetailData.pic,
                        dpjp: presenter.examDetailData.dpjp
                    )

                    AppCard(
                        icon: AppText.Icon.docTextMagnifyingglass,
                        title: AppTextExamDetail.examinationResult1Title,
                        spacing: Decimal.d16
                    ) {
                        VStack(alignment: .leading) {
                            Text(AppTextExamDetail.staffInterpretationTitle)
                                .font(AppTypography.s5)
                                .foregroundColor(AppColors.slate300)
                                
                                let interpretasiPetugas = presenter.examinations.first?.expertResult ?? AppTextExamDetail.notAvailable
                                
                                if interpretasiPetugas != AppTextExamDetail.notAvailable {
                                    GradingCardComponent(
                                        type: GradingType(rawValue: interpretasiPetugas) ?? .unknown,
                                        confidenceLevel: .lowConfidence,
                                        isExpert: true
                                    )
                                } else {
                                    Text(AppTextExamDetail.notAvailable)
                                        .font(AppTypography.p4)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(AppColors.slate50)
                                        .cornerRadius(20)
                                }
                        }
                        ExtendedCard(data: [
                            (AppTextExamDetail.slideIdKey, presenter.examinations.first?.slideId ?? AppValue.empty),
                            (AppTextExamDetail.preparationTypeKey, presenter.examinations.first?.preparationType ?? AppValue.empty)
                        ], titleSize: AppTypography.s5)
                    }

                    AppCard(
                        icon: AppText.Icon.docTextMagnifyingglass,
                        title: AppTextExamDetail.examinationResult2Title,
                        spacing: Decimal.d16
                    ) {
                        VStack(alignment: .leading) {
                            Text(AppTextExamDetail.staffInterpretationTitle)
                                .font(AppTypography.s5)
                                .foregroundColor(AppColors.slate300)
                            
                            let interpretasiPetugas = presenter.examinations.count > 1 ? (presenter.examinations[1].expertResult ?? AppTextExamDetail.notAvailable) : AppTextExamDetail.notAvailable
                            
                            if interpretasiPetugas != AppTextExamDetail.notAvailable {
                                GradingCardComponent(
                                    type: GradingType(rawValue: interpretasiPetugas) ?? .unknown,
                                    confidenceLevel: .lowConfidence,
                                    isExpert: true
                                )
                            } else {
                                Text(AppTextExamDetail.notAvailable)
                                    .font(AppTypography.p4)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(AppColors.slate50)
                                    .cornerRadius(20)
                            }
                        }
                        ExtendedCard(data: [
                            (AppTextExamDetail.slideIdKey, presenter.examinations.count > 1 ? presenter.examinations[1].slideId : AppValue.empty),
                            (AppTextExamDetail.preparationTypeKey, presenter.examinations.count > 1 ? presenter.examinations[1].preparationType : AppValue.empty)
                        ], titleSize: AppTypography.s5)
                    }
                    VStack(spacing: Decimal.d16) {
                        AppButton(
                            title: AppTextExamDetail.viewPdfButton,
                            rightIcon: AppText.Icon.docText,
                            colorType: .secondary,
                            size: .small,
                            isEnabled: true
                        ) {
                            resultPresenter.navigateToPDFView()
                        }
                        
                        AppButton(
                            title: AppTextExamDetail.reportToSitbButton,
                            rightIcon: AppText.Icon.paperplane,
                            size: .small,
                            isEnabled: true
                        ) {
                            print("Lihat PDF Tapped")
                        }
                    }
                }
            }
            .padding(.horizontal, Decimal.d16)
            .navigationTitle(AppTextExamDetail.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Router.shared.navigateBack()
                    }) {
                        HStack {
                            Image(AppText.Icon.back)
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
    ExamDetailAdminView(examId: "6f4e5288-3dfd-4be4-8a2e-8c60f09f07e2", patientId: "d0c1a2b3-4f5e-6789-91ab-cdef12345678")
}
