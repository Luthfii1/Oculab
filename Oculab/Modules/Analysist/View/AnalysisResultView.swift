//
//  AnalysisResultView.swift
//  Oculab
//
//  Created by Risa on 14/10/24.
//

import SwiftUI

struct AnalysisResultView: View {
    var examinationId: String

    @StateObject private var presenter = AnalysisResultPresenter()

    var body: some View {
        ZStack {
            VStack {
                HeaderViewComponent(
                    isLeavePopUpVisible: $presenter.isLeavePopUpVisible,
                    onClose: {
                        presenter.handleHeaderClose(examinationId: examinationId)
                    }
                )

                AppStepper(
                    stepTitles: AppTextAnalysisResult.stepTitles,
                    currentStep: AppTextAnalysisResult.currentStepIndex
                )
                .padding(.vertical, Decimal.d16)

                if let examination = presenter.examinationResult {
                    if presenter.shouldShowAnalyzingUI {
                        AnalyzingExaminationProgressView(examinationId: examinationId)
                            .environmentObject(presenter)
                    } else if presenter.shouldShowResultsUI {
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: Decimal.d24) {
                                if let errorMessage = presenter.errorMessage {
                                    Text(errorMessage)
                                        .font(AppTypography.p3)
                                        .foregroundStyle(AppColors.red500)
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(AppColors.red50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .padding(.horizontal, Decimal.d20)
                                }

                                ImageSectionComponent(presenter: presenter, examination: examination)
                                InterpretationSectionComponent(
                                    examination: examination
                                )
                                .environmentObject(presenter)
                            }
                        }
                    }
                } else {
                    Spacer()
                    Text(AppTextAnalysisResult.loadingExaminationMessage)
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                }
            }
            .onAppear {
                AnalysisResultSessionStore.shared.register(presenter, for: examinationId)
                presenter.beginExaminationTracking(examinationId: examinationId)
                Task {
                    await presenter.fetchData(examinationId: examinationId)
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(for: .fovVerificationUpdated)
            ) { notification in
                guard let examId = notification.userInfo?["examId"] as? String,
                      examId.lowercased() == examinationId.lowercased() else {
                    return
                }
                Task {
                    await presenter.refreshFOVData(examinationId: examinationId)
                }
            }

            Spacer()

            ConfirmationPopups(examinationId: examinationId)
                .environmentObject(presenter)
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    AnalysisResultView(examinationId: "6f4e5288-3dfd-4be4-8a2e-8c60f09f07e2")
}
