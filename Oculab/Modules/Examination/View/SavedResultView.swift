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
                        icon: AppIcon.personFill,
                        title: AppTextExamSavedResult.titlePatientDataCard,
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

                    ExtendableCard(
                        icon: AppIcon.docTextMagnifyingglass,
                        title: AppTextExamSavedResult.titleDetailsExamCard,
                        isExtendable: true,
                        data: [
                            (key: AppMedical.Examination.slideId, value: presenter.examDetailData.slideId),
                            (key: AppMedical.Examination.purpose, value: presenter.examDetailData.examinationGoal),
                            (key: AppMedical.Examination.specimenType, value: presenter.examDetailData.type),
                        ],
                        titleSize: AppTypography.s6
                    )

                    AppCard(icon: AppIcon.photo, title: AppTextExam.titleResultImages, spacing: Decimal.d16) {
                        VStack(alignment: .leading, spacing: Decimal.d16) {
                            Text(AppTextExamCompImageSection.imageResultInstruction)
                                .font(AppTypography.p3)
                                .foregroundStyle(AppColors.slate300)

                            // FOV folder buttons
                            ForEach([FOVType.BTA0, FOVType.BTA1TO9, FOVType.BTAABOVE9], id: \.self) { fovType in
                                if let count = resultPresenter.fovCount(for: fovType), count > 0 {
                                    Button {
                                        resultPresenter.navigateToAlbum(fovGroup: fovType)
                                    } label: {
                                        FolderCardComponent(
                                            title: fovType,
                                            numOfImage: count
                                        )
                                    }
                                }
                            }
                        }
                    }

                    AppCard(
                        icon: AppIcon.textBadgeCheckmark,
                        title: AppTextExam.titleResultInterpretation,
                        spacing: Decimal.d24,
                        isGrading: .FINISHED
                    ) {
                        VStack(alignment: .leading, spacing: Decimal.d8) {
                            Text(AppMedical.Examination.staffInterpretation)
                                .font(AppTypography.s5)
                                .foregroundColor(AppColors.slate300)
                            GradingCardComponent(
                                type: resultPresenter.examinationResult?.expertGrading ?? .unknown,
                                isExpert: true,
                                expertNote: resultPresenter.examinationResult?.expertNote
                            )
                        }

                        VStack(alignment: .leading, spacing: Decimal.d8) {
                            Text(AppMedical.Examination.systemInterpretation)
                                .font(AppTypography.s5)
                                .foregroundColor(AppColors.slate300)
                            HStack(alignment: .top) {
                                Image(systemName: AppIcon.warning)
                                    .foregroundColor(AppColors.orange500)

                                Text(AppTextExamSavedResult.systemInterpretationWarning)
                                    .font(AppTypography.p4)
                            }

                            // System grading component with conditional count
                            GradingCardComponent(
                                type: resultPresenter.systemGrading,
                                n: resultPresenter.systemGradingCount
                            )
                        }

                        VStack(alignment: .leading, spacing: Decimal.d16) {
                            AppButton(
                                title: AppTextExamSavedResult.actionViewPdf,
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
                                isEnabled: false
                            ) {
                                Logger.debug("View PDF button tapped", category: .examination)
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
                            Image(AppImage.back)
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    presenter.resetState()
                    resultPresenter.resetState()
                    await presenter.fetchData(examId: examId, patientId: patientId, userRole: .LAB)
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
    SavedResultView(examId: "6f4e5288-3dfd-4be4-8a2e-8c60f09f07e2", patientId: "d0c1a2b3-4f5e-6789-91ab-cdef12345678")
}
