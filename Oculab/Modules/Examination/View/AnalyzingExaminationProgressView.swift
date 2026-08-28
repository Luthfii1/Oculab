//
//  AnalyzingExaminationProgressView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 17/04/25.
//

import SwiftUI

struct AnalyzingExaminationProgressView: View {
    var examinationId: String
    @EnvironmentObject private var presenter: AnalysisResultPresenter

    private var statusMessage: String {
        if presenter.hasAnalysisFailed {
            return presenter.analysisFailureMessage ?? AppTextExamProgress.analysisFailedDefault
        }

        if presenter.isAnalysisQueued {
            return AppTextExamProgress.analysisQueuedSubtitle
        }

        if presenter.examinationResult?.statusExamination == .NEEDVALIDATION, !presenter.hasFOVData {
            return AppTextExamProgress.loadingImagesSubtitle
        }

        let message = presenter.analysisStatusMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        if message.isEmpty || message == AppTextExamProgress.analyzingTitle {
            return AppTextExamProgress.analyzingSubtitle
        }
        return message
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if presenter.hasAnalysisFailed {
                        failureHeroCard
                        failureInstructionsCard
                    } else if presenter.isAnalysisQueued {
                        queuedHeroCard
                        queuedInstructionsCard
                    } else {
                        progressHeroCard
                        instructionsCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .refreshable {
                Task {
                    if presenter.hasAnalysisFailed {
                        await presenter.checkAnalysisStatus(examinationId: examinationId)
                    } else {
                        await presenter.refreshExaminationStatus(examinationId: examinationId)
                    }
                }
            }

            footer
        }
        .background(AppColors.slate0)
    }

    private var failureHeroCard: some View {
        VStack(spacing: 20) {
            Text(presenter.analysisFailureTitle)
                .font(AppTypography.s4_1)
                .foregroundStyle(AppColors.slate900)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: AppIcon.warning)
                .font(.system(size: 48))
                .foregroundStyle(AppColors.orange500)

            Text(statusMessage)
                .font(AppTypography.p2)
                .foregroundStyle(AppColors.slate600)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(AppColors.orange50)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var failureInstructionsCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: AppIcon.info)
                .font(.system(size: 20))
                .foregroundStyle(AppColors.orange500)
                .padding(.top, 2)

            Text(presenter.analysisRecoveryHint)
                .font(AppTypography.p3)
                .foregroundStyle(AppColors.slate600)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.slate0)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.slate100, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var queuedHeroCard: some View {
        VStack(spacing: 20) {
            Text(AppTextExamProgress.analysisQueuedTitle)
                .font(AppTypography.s4_1)
                .foregroundStyle(AppColors.slate900)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: AppIcon.clockArrowCirclepath)
                .font(.system(size: 48))
                .foregroundStyle(AppColors.purple500)

            Text(statusMessage)
                .font(AppTypography.p2)
                .foregroundStyle(AppColors.slate600)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .fixedSize(horizontal: false, vertical: true)

            if presenter.analysisProgress > 0 {
                AnalysisProgressRing(progress: presenter.analysisProgress)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(AppColors.slate50)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var queuedInstructionsCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: AppIcon.info)
                .font(.system(size: 20))
                .foregroundStyle(AppColors.purple500)
                .padding(.top, 2)

            Text(AppTextExamDetail.analysisQueuedMessage)
                .font(AppTypography.p3)
                .foregroundStyle(AppColors.slate600)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.slate0)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.slate100, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var progressHeroCard: some View {
        VStack(spacing: 20) {
            Text(AppTextExamProgress.analyzingTitle)
                .font(AppTypography.s4_1)
                .foregroundStyle(AppColors.slate900)
                .frame(maxWidth: .infinity, alignment: .leading)

            AnalysisProgressRing(progress: presenter.analysisProgress)

            Text(statusMessage)
                .font(AppTypography.p2)
                .foregroundStyle(AppColors.slate600)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .fixedSize(horizontal: false, vertical: true)

            LottieHelper(animationName: AppTextExamProgress.loadingAnimationName)
                .aspectRatio(contentMode: .fit)
                .frame(height: 56)
                .frame(maxWidth: 160)
                .opacity(0.9)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(AppColors.purple50)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var instructionsCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: AppIcon.info)
                .font(.system(size: 20))
                .foregroundStyle(AppColors.purple500)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 8) {
                Text(AppTextExamProgress.backgroundInstruction)
                    .font(AppTypography.p3)
                    .foregroundStyle(AppColors.slate600)
                    .fixedSize(horizontal: false, vertical: true)

                Text(AppTextExamProgress.refreshInstruction)
                    .font(AppTypography.p3)
                    .foregroundStyle(AppColors.slate400)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.slate0)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.slate100, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider()

            VStack(spacing: 10) {
                if presenter.hasAnalysisFailed {
                    if presenter.isAnalysisStalled {
                        AppButton(
                            title: AppTextExamProgress.buttonCheckStatus,
                            size: .large,
                            isEnabled: true
                        ) {
                            Task {
                                await presenter.checkAnalysisStatus(examinationId: examinationId)
                            }
                        }

                        AppButton(
                            title: AppTextExamProgress.buttonResubmitVideo,
                            colorType: .secondary,
                            size: .large,
                            isEnabled: true
                        ) {
                            Task {
                                await presenter.retryAnalysis(examinationId: examinationId)
                            }
                        }
                    } else {
                        AppButton(
                            title: AppTextExamProgress.buttonResubmitVideo,
                            size: .large,
                            isEnabled: true
                        ) {
                            Task {
                                await presenter.retryAnalysis(examinationId: examinationId)
                            }
                        }

                        AppButton(
                            title: AppTextExamProgress.buttonCheckStatus,
                            colorType: .secondary,
                            size: .large,
                            isEnabled: true
                        ) {
                            Task {
                                await presenter.checkAnalysisStatus(examinationId: examinationId)
                            }
                        }
                    }

                    AppButton(
                        title: AppTextExamProgress.buttonBackToTasks,
                        colorType: .secondary,
                        size: .large,
                        isEnabled: true
                    ) {
                        presenter.exitFromFlow(examinationId: examinationId)
                    }
                } else {
                    AppButton(
                        title: AppTextExamProgress.buttonCheckStatus,
                        colorType: .secondary,
                        size: .large,
                        isEnabled: true
                    ) {
                        Task {
                            await presenter.refreshExaminationStatus(examinationId: examinationId)
                        }
                    }

                    AppButton(
                        title: AppTextExamProgress.buttonBackToTasks,
                        colorType: .primary,
                        size: .large,
                        isEnabled: true
                    ) {
                        presenter.exitFromFlow(examinationId: examinationId)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(AppColors.slate0)
    }
}

#Preview {
    AnalyzingExaminationProgressView(examinationId: "6f4e5288-3dfd-4be4-8a2e-8c60f09f07e2")
        .environmentObject({
            let presenter = AnalysisResultPresenter()
            presenter.analysisProgress = 55
            presenter.analysisStatusMessage = AppTextExamProgress.extractingFovsPreview
            return presenter
        }())
}
