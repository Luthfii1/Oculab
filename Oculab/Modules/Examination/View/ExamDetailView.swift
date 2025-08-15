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
                    stepTitles: [AppTextExamDetail.dataPemeriksaanStep, AppTextExamDetail.hasilPemeriksaanStep],
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
                                icon: AppIcon.personFill,
                                title: AppTextExamDetail.titlePatientDataCard,
                                spacing: Decimal.d8,
                                isBorderDisabled: true
                            ) {
                                ExtendedCard(data: [
                                    (key: AppPatient.name, value: presenter.patientDetailData.name),
                                    (key: AppPatient.nik, value: presenter.patientDetailData.nik),
                                    (key: AppPatient.dateOfBirth, value: presenter.patientDetailData.dob),
                                    (key: AppPatient.gender, value: presenter.patientDetailData.sex),
                                    (key: AppPatient.bpjsNumber, value: presenter.patientDetailData.bpjs)
                                ], titleSize: AppTypography.s5)
                            }

                            AppCard(
                                icon: AppIcon.docTextMagnifyingglass,
                                title: AppTextExamDetail.slideDetailTitle,
                                spacing: Decimal.d8,
                                isBorderDisabled: true
                            ) {
                                ExtendedCard(data: [
                                    (key: AppMedical.Examination.slideId, value: presenter.examDetailData.slideId),
                                    (key: AppMedical.Examination.purpose, value: presenter.examDetailData.examinationGoal),
                                    (key: AppMedical.Examination.specimenType, value: presenter.examDetailData.type)
                                ], titleSize: AppTypography.s5)
                            }

                            VideoInput(
                                title: AppTextExamDetail.slideImageTitle,
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
                        rightIcon: AppIcon.arrowRight,
                        size: .large,
                        isEnabled: presenter.isButtonEnabled
                    ) {
                        Task {
                            await presenter.handleSubmit()
                            presenter.navigateToAnalysisResult(examinationId: presenter.examDetailData.examinationId)
                        }
                    }
                }
                .padding(.horizontal, Decimal.d20)
                .navigationTitle(AppTextExamDetail.newExaminationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presenter.recordVideo = nil
                            presenter.videoPresenter.previewURL = nil

                            Router.shared.navigateBack()
                        }) {
                            HStack {
                                Image(AppImage.back)
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
                Logger.debug("Loading state: \(presenter.isLoading)", category: .examination)
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
