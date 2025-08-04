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

    @StateObject private var videoRecordPresenter = VideoRecordPresenter.shared
    @StateObject var presenter = ExamDataPresenter(interactor: ExamInteractor())
    @State private var showGuidelines = false
    @State private var didFinishOnboarding = false

    var body: some View {
        NavigationView {
            VStack {
                AppStepper(
                    stepTitles: [AppText.Examination.DetailViews.dataPemeriksaanStep, AppText.Examination.DetailViews.hasilPemeriksaanStep],
                    currentStep: 0
                ).padding(.top, Decimal.d12)

                Spacer().frame(height: Decimal.d24)

                VStack(spacing: Decimal.d24) {
                    if presenter.isLoading == true {
                        ProgressView()
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LaborantInfoComponent(
                                pic: presenter.examDetailData.pic,
                                dpjp: presenter.examDetailData.dpjp
                            )

                            AppCard(
                                icon: AppText.Icon.personFill,
                                title: AppText.Examination.DetailViews.patientDataTitle,
                                spacing: Decimal.d8,
                                isBorderDisabled: true
                            ) {
                                ExtendedCard(data: [
                                    (key: AppText.Examination.DetailViews.patientNameKey, value: presenter.patientDetailData.name),
                                    (key: AppText.Examination.DetailViews.patientNikKey, value: presenter.patientDetailData.nik),
                                    (key: AppText.Examination.DetailViews.patientDobKey, value: presenter.patientDetailData.dob),
                                    (key: AppText.Examination.DetailViews.patientSexKey, value: presenter.patientDetailData.sex),
                                    (key: AppText.Examination.DetailViews.patientBpjsKey, value: presenter.patientDetailData.bpjs)
                                ], titleSize: AppTypography.s5)
                            }

                            AppCard(
                                icon: AppText.Icon.docTextMagnifyingglass,
                                title: AppText.Examination.DetailViews.slideDetailTitle,
                                spacing: Decimal.d8,
                                isBorderDisabled: true
                            ) {
                                ExtendedCard(data: [
                                    (key: AppText.Examination.DetailViews.slideIdKey, value: presenter.examDetailData.slideId),
                                    (key: AppText.Examination.DetailViews.examinationGoalKey, value: presenter.examDetailData.examinationGoal),
                                    (key: AppText.Examination.DetailViews.preparationTypeKey, value: presenter.examDetailData.type)
                                ], titleSize: AppTypography.s5)
                            }

                            VideoInput(
                                title: AppText.Examination.DetailViews.slideImageTitle,
                                isRequired: true,
                                isEmpty: false,
                                showOnboardingGuidelines: $showGuidelines,
                                didFinishOnboarding: $didFinishOnboarding,
                                selectedURL: $presenter.recordVideo
                            ).environmentObject(presenter)

                            VStack(alignment: .leading, spacing: Decimal.d24) {}
                        }
                    }

                    AppButton(
                        title: presenter.buttonTitle,
                        rightIcon: AppText.Icon.arrowRight,
                        size: .large,
                        isEnabled: presenter.buttonEnabled()
                    ) {
                        Task {
                            await presenter.handleSubmit()
                            presenter.navigateToAnalysisResult(examinationId: presenter.examDetailData.examinationId)
                        }
                    }
                }
                .padding(.horizontal, Decimal.d20)
                .navigationTitle(AppText.Examination.DetailViews.newExaminationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presenter.recordVideo = nil
                            presenter.videoPresenter.previewURL = nil

                            Router.shared.navigateBack()
                        }) {
                            HStack {
                                Image(AppText.Icon.back)
                            }
                        }
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
                print(presenter.isLoading)
            }
        }
        .onChange(of: videoRecordPresenter.previewURL) {
            presenter.recordVideo = videoRecordPresenter.previewURL
        }
    }
}

#Preview {
    ExamDetailView(examId: "6f4e5288-3dfd-4be4-8a2e-8c60f09f07e2", patientId: "f3g4h5i6-7891-abcd-ef12-3456789abcdef")
}
