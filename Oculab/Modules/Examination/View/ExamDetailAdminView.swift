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
                        title: AppText.Examination.DetailViews.patientDataTitle,
                        isExtendable: true,
                        data: [
                            (key: AppText.Examination.DetailViews.patientNameKey, value: presenter.patientDetailData.name),
                            (key: AppText.Examination.DetailViews.patientNikKey, value: presenter.patientDetailData.nik),
                            (key: AppText.Examination.DetailViews.patientDobKey, value: presenter.patientDetailData.dob),
                            (key: AppText.Examination.DetailViews.patientSexKey, value: presenter.patientDetailData.sex),
                            (key: AppText.Examination.DetailViews.patientBpjsKey, value: presenter.patientDetailData.bpjs),
                        ],
                        titleSize: AppTypography.s5
                    )

                    LaborantInfoComponent(
                        pic: presenter.examDetailData.pic,
                        dpjp: presenter.examDetailData.dpjp
                    )

                    AppCard(
                        icon: AppText.Icon.docTextMagnifyingglass,
                        title: AppText.Examination.DetailViews.examinationResult1Title,
                        spacing: Decimal.d16
                    ) {
                        VStack(alignment: .leading) {
                            Text(AppText.Examination.DetailViews.staffInterpretationTitle)
                                .font(AppTypography.s5)
                                .foregroundColor(AppColors.slate300)
                                
                                let interpretasiPetugas = presenter.examinations.first?.expertResult ?? AppText.Examination.DetailViews.notAvailable
                                
                                if interpretasiPetugas != AppText.Examination.DetailViews.notAvailable {
                                    GradingCardComponent(
                                        type: GradingType(rawValue: interpretasiPetugas) ?? .unknown,
                                        confidenceLevel: .lowConfidence,
                                        isExpert: true
                                    )
                                } else {
                                    Text(AppText.Examination.DetailViews.notAvailable)
                                        .font(AppTypography.p4)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(AppColors.slate50)
                                        .cornerRadius(20)
                                }
                        }
                        ExtendedCard(data: [
                            (AppText.Examination.DetailViews.slideIdKey, presenter.examinations.first?.slideId ?? AppText.Common.emptyString),
                            (AppText.Examination.DetailViews.preparationTypeKey, presenter.examinations.first?.preparationType ?? AppText.Common.emptyString)
                        ], titleSize: AppTypography.s5)
                    }

                    AppCard(
                        icon: AppText.Icon.docTextMagnifyingglass,
                        title: AppText.Examination.DetailViews.examinationResult2Title,
                        spacing: Decimal.d16
                    ) {
                        VStack(alignment: .leading) {
                            Text(AppText.Examination.DetailViews.staffInterpretationTitle)
                                .font(AppTypography.s5)
                                .foregroundColor(AppColors.slate300)
                            
                            let interpretasiPetugas = presenter.examinations.count > 1 ? (presenter.examinations[1].expertResult ?? AppText.Examination.DetailViews.notAvailable) : AppText.Examination.DetailViews.notAvailable
                            
                            if interpretasiPetugas != AppText.Examination.DetailViews.notAvailable {
                                GradingCardComponent(
                                    type: GradingType(rawValue: interpretasiPetugas) ?? .unknown,
                                    confidenceLevel: .lowConfidence,
                                    isExpert: true
                                )
                            } else {
                                Text(AppText.Examination.DetailViews.notAvailable)
                                    .font(AppTypography.p4)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(AppColors.slate50)
                                    .cornerRadius(20)
                            }
                        }
                        ExtendedCard(data: [
                            (AppText.Examination.DetailViews.slideIdKey, presenter.examinations.count > 1 ? presenter.examinations[1].slideId : AppText.Common.emptyString),
                            (AppText.Examination.DetailViews.preparationTypeKey, presenter.examinations.count > 1 ? presenter.examinations[1].preparationType : AppText.Common.emptyString)
                        ], titleSize: AppTypography.s5)
                    }
                    VStack(spacing: Decimal.d16) {
                        AppButton(
                            title: AppText.Examination.DetailViews.viewPdfButton,
                            rightIcon: AppText.Icon.docText,
                            colorType: .secondary,
                            size: .small,
                            isEnabled: true
                        ) {
                            resultPresenter.navigateToPDFView()
                        }
                        
                        AppButton(
                            title: AppText.Examination.DetailViews.reportToSitbButton,
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
            .navigationTitle(AppText.Examination.DetailViews.navigationTitle)
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
