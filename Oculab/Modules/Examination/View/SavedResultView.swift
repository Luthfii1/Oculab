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

                    ExtendableCard(
                        icon: AppText.Icon.docTextMagnifyingglass,
                        title: AppText.Examination.SavedResultView.examinationDetailTitle,
                        isExtendable: true,
                        data: [
                            (key: AppText.Examination.DetailViews.slideIdKey, value: presenter.examDetailData.slideId),
                            (key: AppText.Examination.SavedResultView.examinationReasonKey, value: presenter.examDetailData.examinationGoal),
                            (key: AppText.Examination.DetailViews.preparationTypeKey, value: presenter.examDetailData.type),
                        ],
                        titleSize: AppTypography.s6
                    )

                    AppCard(icon: AppText.Icon.photo, title: AppText.Examination.SavedResultView.imageResultTitle, spacing: Decimal.d16) {
                        VStack(alignment: .leading, spacing: Decimal.d16) {
                            Text(AppText.Examination.SavedResultView.imageResultInstruction)
                                .font(AppTypography.p3)
                                .foregroundStyle(AppColors.slate300)

                            RoundedRectangle(cornerRadius: Decimal.d8)
                                .foregroundStyle(AppColors.slate50)
                                .frame(height: 200)

                            if resultPresenter.groupedFOVs?.bta0.isEmpty != true {
                                Button {
                                    resultPresenter.navigateToAlbum(fovGroup: .BTA0)
                                } label: {
                                    FolderCardComponent(
                                        title: .BTA0,
                                        numOfImage: resultPresenter.groupedFOVs?.bta0.count ?? 0
                                    )
                                }
                            }

                            if resultPresenter.groupedFOVs?.bta1to9.isEmpty != true {
                                Button {
                                    resultPresenter.navigateToAlbum(fovGroup: .BTA1TO9)
                                } label: {
                                    FolderCardComponent(
                                        title: .BTA1TO9,
                                        numOfImage: resultPresenter.groupedFOVs?.bta1to9.count ?? 0
                                    )
                                }
                            }

                            if resultPresenter.groupedFOVs?.btaabove9.isEmpty != true {
                                Button {
                                    resultPresenter.navigateToAlbum(fovGroup: .BTAABOVE9)
                                } label: {
                                    FolderCardComponent(
                                        title: .BTAABOVE9,
                                        numOfImage: resultPresenter.groupedFOVs?.btaabove9.count ?? 0
                                    )
                                }
                            }
                        }
                    }

                    AppCard(
                        icon: AppText.Icon.textBadgeCheckmark,
                        title: AppText.Examination.SavedResultView.interpretationResultTitle,
                        spacing: Decimal.d24,
                        isGrading: .FINISHED
                    ) {
                        VStack(alignment: .leading, spacing: Decimal.d8) {
                            Text(AppText.Examination.SavedResultView.staffInterpretationTitle)
                                .font(AppTypography.s5)
                                .foregroundColor(AppColors.slate300)
                            GradingCardComponent(
                                type: resultPresenter.examinationResult?.expertGrading ?? .unknown,
                                confidenceLevel: .lowConfidence,
                                isExpert: true,
                                expertNote: resultPresenter.examinationResult?.expertNote
                            )
                        }

                        VStack(alignment: .leading, spacing: Decimal.d8) {
                            Text(AppText.Examination.SavedResultView.systemInterpretationTitle)
                                .font(AppTypography.s5)
                                .foregroundColor(AppColors.slate300)
                            HStack(alignment: .top) {
                                Image(systemName: AppText.Icon.exclamationmarkTriangleFill)
                                    .foregroundColor(AppColors.orange500)

                                Text(AppText.Examination.SavedResultView.systemInterpretationWarning)
                                    .font(AppTypography.p4)
                            }

                            if resultPresenter.examinationResult?.systemGrading == .NEGATIVE {
                                GradingCardComponent(
                                    type: resultPresenter.examinationResult?.systemGrading ?? .unknown,
                                    confidenceLevel: ConfidenceLevel
                                        .classify(
                                            aggregatedConfidence: resultPresenter.examinationResult?
                                                .confidenceLevelAggregated ?? 0.0
                                        )
                                )
                            } else if resultPresenter.examinationResult?.systemGrading == .Plus2 {
                                GradingCardComponent(
                                    type: resultPresenter.examinationResult?.systemGrading ?? .unknown,
                                    confidenceLevel: ConfidenceLevel
                                        .classify(
                                            aggregatedConfidence: resultPresenter.examinationResult?
                                                .confidenceLevelAggregated ?? 0.0
                                        ),
                                    n: resultPresenter.groupedFOVs?.bta1to9.count ?? 0
                                )
                            } else if resultPresenter.examinationResult?.systemGrading == .Plus3 {
                                GradingCardComponent(
                                    type: resultPresenter.examinationResult?.systemGrading ?? .unknown,
                                    confidenceLevel: ConfidenceLevel
                                        .classify(
                                            aggregatedConfidence: resultPresenter.examinationResult?
                                                .confidenceLevelAggregated ?? 0.0
                                        ),
                                    n: resultPresenter.groupedFOVs?.btaabove9.count ?? 0
                                )
                            } else {
                                GradingCardComponent(
                                    type: resultPresenter.examinationResult?.systemGrading ?? .unknown,
                                    confidenceLevel: ConfidenceLevel
                                        .classify(
                                            aggregatedConfidence: resultPresenter.examinationResult?
                                                .confidenceLevelAggregated ?? 0.0
                                        ),
                                    n: resultPresenter.examinationResult?.bacteriaTotalCount ?? 0
                                )
                            }
                        }

                        VStack(alignment: .leading, spacing: Decimal.d16) {
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
            }
            .padding(.horizontal, Decimal.d16)
            .navigationTitle(presenter.examDetailData.slideId)
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
                    await presenter.fetchData(examId: examId, patientId: patientId, userRole: .LAB)
                    await resultPresenter.fetchData(examinationId: examId)
                }
            }
        }.navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SavedResultView(examId: "6f4e5288-3dfd-4be4-8a2e-8c60f09f07e2", patientId: "d0c1a2b3-4f5e-6789-91ab-cdef12345678")
}
