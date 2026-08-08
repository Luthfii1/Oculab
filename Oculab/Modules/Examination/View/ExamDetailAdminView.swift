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

    @StateObject private var presenter = ExamDataPresenter(interactor: ExamInteractor())
    @StateObject private var resultPresenter = AnalysisResultPresenter()

    var body: some View {
        NavigationView {
            ScrollView {
                Spacer().frame(height: Decimal.d24)

                VStack(alignment: .leading, spacing: Decimal.d24) {
                    ExtendableCard(
                        icon: AppIcon.personFill,
                        title: AppTextExamDetail.titlePatientDataCard,
                        isExtendable: true,
                        data: [
                            (key: AppPatient.name, value: presenter.patientDetailData.name),
                            (key: AppPatient.nik, value: presenter.patientDetailData.nik),
                            (key: AppPatient.dateOfBirth, value: presenter.patientDetailData.dob),
                            (key: AppPatient.gender, value: presenter.patientDetailData.sex),
                            (key: AppPatient.bpjsNumber, value: presenter.patientDetailData.bpjs),
                        ],
                        titleSize: AppTypography.s5
                    )

                    LaborantInfoComponent(
                        pic: presenter.examDetailData.pic,
                        dpjp: presenter.examDetailData.dpjp
                    )

                    AppCard(
                        icon: AppIcon.docTextMagnifyingglass,
                        title: AppTextExamDetail.examinationResult1Title,
                        spacing: Decimal.d16
                    ) {
                        VStack(alignment: .leading) {
                            Text(AppMedical.Examination.staffInterpretation)
                                .font(AppTypography.s5)
                                .foregroundColor(AppColors.slate300)
                                
                            // Staff interpretation component
                            if presenter.staffInterpretation != AppState.notAvailable {
                                GradingCardComponent(
                                    type: GradingType(rawValue: presenter.staffInterpretation) ?? .unknown,
                                    isExpert: true
                                )
                            } else {
                                Text(AppState.notAvailable)
                                    .font(AppTypography.p4)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(AppColors.slate50)
                                    .cornerRadius(20)
                            }
                        }
                        ExtendedCard(data: [
                            (AppMedical.Examination.slideId, presenter.firstExamination?.slideId ?? AppValue.empty),
                            (AppMedical.Examination.specimenType, presenter.firstExamination?.preparationType ?? AppValue.empty)
                        ], titleSize: AppTypography.s5)
                    }

                    AppCard(
                        icon: AppIcon.docTextMagnifyingglass,
                        title: AppTextExamDetail.examinationResult2Title,
                        spacing: Decimal.d16
                    ) {
                        VStack(alignment: .leading) {
                            Text(AppMedical.Examination.staffInterpretation)
                                .font(AppTypography.s5)
                                .foregroundColor(AppColors.slate300)
                            
                            let interpretasiPetugas = presenter.secondExamination?.expertResult ?? AppState.notAvailable
                            
                            if interpretasiPetugas != AppState.notAvailable {
                                GradingCardComponent(
                                    type: GradingType(rawValue: interpretasiPetugas) ?? .unknown,
                                    isExpert: true
                                )
                            } else {
                                Text(AppState.notAvailable)
                                    .font(AppTypography.p4)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(AppColors.slate50)
                                    .cornerRadius(20)
                            }
                        }
                        ExtendedCard(data: [
                            (AppMedical.Examination.slideId, presenter.secondExamination?.slideId ?? AppValue.empty),
                            (AppMedical.Examination.specimenType, presenter.secondExamination?.preparationType ?? AppValue.empty)
                        ], titleSize: AppTypography.s5)
                    }
                    VStack(spacing: Decimal.d16) {
                        AppButton(
                            title: AppTextExamDetail.buttonViewPDF,
                            rightIcon: AppIcon.document,
                            colorType: .secondary,
                            size: .small,
                            isEnabled: true
                        ) {
                            resultPresenter.navigateToPDFView()
                        }
                        
                        AppButton(
                            title: AppTextExamDetail.reportToSitbButton,
                            rightIcon: AppIcon.paperplane,
                            size: .small,
                            isEnabled: false // Disable until functionality is implemented
                        ) {
                            Logger.debug("View PDF button tapped", category: .examination)
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
                            Image(AppImage.back)
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    presenter.resetState()
                    resultPresenter.resetState()
                    await presenter.fetchData(examId: examId, patientId: patientId, userRole: .ADMIN)
                    await resultPresenter.fetchData(examinationId: examId)
                }
            }
            .onDisappear {
                presenter.resetState()
                resultPresenter.resetState()
            }
        }.navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ExamDetailAdminView(examId: "6f4e5288-3dfd-4be4-8a2e-8c60f09f07e2", patientId: "d0c1a2b3-4f5e-6789-91ab-cdef12345678")
}
