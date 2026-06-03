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

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.2)

                AnalysisProgressRing(
                    progress: presenter.analysisProgress,
                    message: presenter.analysisStatusMessage
                )
                .padding(.bottom, Decimal.d32)

                LottieHelper(animationName: AppTextExamProgress.loadingAnimationName)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: Decimal.d72)
                    .padding(.bottom, Decimal.d24)

                Text(AppTextExamProgress.analyzingTitle)
                    .font(AppTypography.h2)
                    .padding(.bottom, Decimal.d12)

                Text(AppTextExamProgress.backgroundInstruction)
                    .font(AppTypography.p3)
                    .foregroundStyle(AppColors.slate400)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text(AppTextExamProgress.refreshInstruction)
                    .font(AppTypography.p3)
                    .foregroundStyle(AppColors.slate400)
                    .padding(.top, 8)

                AppButton(
                    title: AppTextExamProgress.buttonBackToTasks,
                    size: .large,
                    isEnabled: true
                ) {
                    Router.shared.popToRoot()
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                Spacer()
            }
        }
        .refreshable {
            Task {
                await presenter.refreshExaminationStatus(examinationId: examinationId)
            }
        }
        .onAppear {
            presenter.startExaminationStatusPolling(examinationId: examinationId)
        }
        .onDisappear {
            presenter.stopExaminationStatusPolling()
        }
    }
}

#Preview {
    AnalyzingExaminationProgressView(examinationId: "6f4e5288-3dfd-4be4-8a2e-8c60f09f07e2")
        .environmentObject(AnalysisResultPresenter())
}
