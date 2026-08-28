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

    @ObservedObject private var videoRecordPresenter = VideoRecordSession.current
    @ObservedObject private var uploadQueue = VideoUploadQueueService.shared
    @StateObject private var presenter = ExamDataPresenter(interactor: ExamInteractor())
    @State private var showGuidelines = false
    @State private var didFinishOnboarding = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                AppStepper(
                    stepTitles: [AppTextExamDetail.dataPemeriksaanStep, AppTextExamDetail.hasilPemeriksaanStep],
                    currentStep: 0
                )
                .padding(.top, 12)
                .padding(.horizontal, 20)

                if presenter.isLoading {
                    Spacer()
                    ProgressView()
                    Text(AppState.loading("examination.detail.loading".localized))
                        .font(AppTypography.p3)
                        .foregroundStyle(AppColors.slate400)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(AppTextExamDetail.reviewSummaryHint)
                                .font(AppTypography.p3)
                                .foregroundStyle(AppColors.slate400)
                                .fixedSize(horizontal: false, vertical: true)

                            LaborantInfoComponent(
                                pic: presenter.examDetailData.pic,
                                dpjp: presenter.examDetailData.dpjp
                            )

                            ExamDetailSectionCard(
                                icon: AppIcon.personFill,
                                title: AppTextExamDetail.titlePatientDataCard
                            ) {
                                ExamDetailFieldList(rows: presenter.patientDisplayRows)
                            }

                            ExamDetailSectionCard(
                                icon: AppIcon.docTextMagnifyingglass,
                                title: AppTextExamDetail.slideDetailTitle
                            ) {
                                ExamDetailFieldList(rows: presenter.specimenDisplayRows)
                            }

                            ExamDetailSectionCard(
                                icon: AppIcon.cameraFill,
                                title: AppTextExamDetail.slideImageTitle
                            ) {
                                VideoInput(
                                    title: AppValue.empty,
                                    isRequired: false,
                                    isEmpty: false,
                                    showOnboardingGuidelines: $showGuidelines,
                                    didFinishOnboarding: $didFinishOnboarding,
                                    selectedURL: $presenter.recordVideo
                                )
                                .environmentObject(presenter)
                            }

                            Spacer().frame(height: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }

                    detailFooter
                }
            }
            .background(AppColors.slate0)
            .navigationTitle(AppTextExamDetail.newExaminationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presenter.recordVideo = nil
                        presenter.videoPresenter.previewURL = nil
                        Router.shared.navigateBack()
                    }) {
                        Image(AppImage.back)
                    }
                }
            }
        }
        .sheet(isPresented: $showGuidelines, onDismiss: {
            didFinishOnboarding = true
        }) {
            GuidelinesOnboardingView()
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            Task {
                await presenter.fetchData(examId: examId, patientId: patientId, userRole: .LAB)
            }
        }
        .onDisappear {
            presenter.resetState()
        }
        .onChange(of: videoRecordPresenter.previewURL) {
            presenter.recordVideo = videoRecordPresenter.previewURL
        }
        .overlay {
            if presenter.isSubmittingExamination {
                ZStack {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(AppTextExamDetail.uploadingVideoMessage)
                            .font(AppTypography.p3)
                            .foregroundStyle(AppColors.slate0)
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                }
            }
        }
        .alert(
            AppState.error,
            isPresented: Binding(
                get: { presenter.submissionError != nil },
                set: { if !$0 { presenter.submissionError = nil } }
            ),
            actions: {
                Button(AppAction.ok) {
                    presenter.submissionError = nil
                }
            },
            message: {
                Text(presenter.submissionError ?? AppValue.empty)
            }
        )
    }

    private var detailFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            if uploadQueue.hasPendingUpload(for: examId) {
                uploadQueueBanner
            }

            if let hint = presenter.startAnalysisHint {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: AppIcon.info)
                        .foregroundStyle(AppColors.purple600)
                    Text(hint)
                        .font(AppTypography.p3)
                        .foregroundStyle(AppColors.slate600)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.purple50)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            AppButton(
                title: presenter.buttonTitle,
                rightIcon: AppIcon.arrowRight,
                size: .large,
                isEnabled: presenter.isButtonEnabled
            ) {
                Task {
                    await presenter.handleSubmit()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppColors.slate0)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    @ViewBuilder
    private var uploadQueueBanner: some View {
        let normalizedExamId = examId.lowercased()
        let state = uploadQueue.uploadState(for: normalizedExamId)
        let isFailed = state == .failed
        let isUploading = uploadQueue.uploadingExaminationId?.lowercased() == normalizedExamId

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                if isUploading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: isFailed ? AppIcon.warning : AppIcon.cloudArrowUp)
                        .foregroundStyle(isFailed ? AppColors.orange500 : AppColors.purple600)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        isUploading
                            ? AppTextExam.uploadQueueUploading
                            : (isFailed ? AppTextExam.uploadQueueFailed : AppTextExam.uploadPendingBadge)
                    )
                    .font(AppTypography.p3)
                    .foregroundStyle(AppColors.slate600)
                    .fixedSize(horizontal: false, vertical: true)

                    if isFailed, let error = uploadQueue.lastUploadError(for: normalizedExamId) {
                        Text(error)
                            .font(AppTypography.p4)
                            .foregroundStyle(AppColors.slate400)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if isFailed {
                AppButton(
                    title: AppAction.retry,
                    colorType: .secondary,
                    size: .small
                ) {
                    Task {
                        await uploadQueue.retry(examinationId: normalizedExamId)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isFailed ? AppColors.orange50 : AppColors.purple50)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ExamDetailView(
        examId: "6f4e5288-3dfd-4be4-8a2e-8c60f09f07e2",
        patientId: "f3g4h5i6-7891-abcd-ef12-3456789abcdef"
    )
}
