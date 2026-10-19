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

    @StateObject private var presenter = ExamDataPresenter(interactor: ExamInteractor())
    @StateObject private var resultPresenter = AnalysisResultPresenter()
    @State private var isLoadingResults = true
    @State private var loadError: String?
    @State private var loadAttempt = 0

    var body: some View {
        NavigationView {
            Group {
                if isLoadingResults {
                    ProgressView(AppTextAnalysisResult.loadingExaminationMessage)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let loadError {
                    VStack(spacing: 16) {
                        Image(systemName: AppIcon.warning)
                            .font(.largeTitle)
                            .foregroundStyle(AppColors.orange500)
                            .accessibilityHidden(true)
                        Text("examination.result.load_error_title".localized)
                            .font(AppTypography.s4_1)
                            .foregroundStyle(AppColors.slate900)
                        Text(loadError)
                            .font(AppTypography.p3)
                            .foregroundStyle(AppColors.slate600)
                            .multilineTextAlignment(.center)
                        AppButton(title: AppAction.retry, size: .large) {
                            loadAttempt += 1
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    resultContent
                }
            }
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
            .task(id: loadAttempt) {
                await loadResults()
            }
            .onDisappear {
                isLoadingResults = true
                presenter.resetState()
                resultPresenter.resetState()
            }
        }.navigationBarBackButtonHidden(true)
    }
    private var resultContent: some View {
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
    }

    @MainActor
    private func loadResults() async {
        guard !Task.isCancelled else { return }
        isLoadingResults = true
        loadError = nil
        presenter.resetState()
        resultPresenter.resetState()
        await presenter.fetchData(examId: examId, patientId: patientId, userRole: .LAB)
        guard !Task.isCancelled else { return }
        await resultPresenter.fetchData(examinationId: examId)
        guard !Task.isCancelled else { return }

        if presenter.patientDetailData.patientId.isEmpty
            || presenter.examDetailData.examinationId.isEmpty
            || resultPresenter.examinationResult == nil {
            loadError = resultPresenter.errorMessage ?? "examination.result.load_error_message".localized
        }
        isLoadingResults = false
    }
}

#Preview {
    SavedResultView(examId: "6f4e5288-3dfd-4be4-8a2e-8c60f09f07e2", patientId: "d0c1a2b3-4f5e-6789-91ab-cdef12345678")
}
