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
    @State private var showPICPicker = false
    @State private var showArchiveConfirm = false
    @State private var csvShareURL: URL?
    @State private var showCsvShare = false

    var body: some View {
        NavigationView {
            ScrollView {
                Spacer().frame(height: Decimal.d24)

                VStack(alignment: .leading, spacing: Decimal.d24) {
                    if presenter.isObservationArchived {
                        Text(AppTextExamDetail.adminArchivedBadge)
                            .font(AppTypography.p4)
                            .foregroundStyle(AppColors.orange700)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppColors.orange50)
                            .clipShape(Capsule())
                    }

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

                    adminActionsSection

                    AppCard(
                        icon: AppIcon.docTextMagnifyingglass,
                        title: AppTextExamDetail.examinationResult1Title,
                        spacing: Decimal.d16
                    ) {
                        VStack(alignment: .leading) {
                            Text(AppMedical.Examination.staffInterpretation)
                                .font(AppTypography.s5)
                                .foregroundColor(AppColors.slate300)

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
                            isEnabled: false
                        ) {
                            Logger.debug("SITB report tapped", category: .examination)
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
            .sheet(isPresented: $showPICPicker) {
                ExamAdminPICPickerSheet { user in
                    Task {
                        if await presenter.adminReassignPIC(
                            observationId: examId,
                            picId: user.id
                        ) {
                            await presenter.fetchData(examId: examId, patientId: patientId, userRole: .ADMIN)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCsvShare) {
                if let csvShareURL {
                    ShareSheetView(items: [csvShareURL])
                }
            }
            .alert(
                AppTextExamDetail.adminArchiveConfirmTitle,
                isPresented: $showArchiveConfirm
            ) {
                Button(AppState.cancel, role: .cancel) {}
                Button(AppTextExamDetail.adminArchiveButton, role: .destructive) {
                    Task {
                        _ = await presenter.adminSetArchived(observationId: examId, archived: true)
                    }
                }
            } message: {
                Text(AppTextExamDetail.adminArchiveConfirmMessage)
            }
            .alert(
                AppState.error,
                isPresented: Binding(
                    get: { presenter.adminActionError != nil },
                    set: { if !$0 { presenter.adminActionError = nil } }
                )
            ) {
                Button(AppAction.ok) { presenter.adminActionError = nil }
            } message: {
                Text(presenter.adminActionError ?? AppValue.empty)
            }
        }
        .navigationBarBackButtonHidden(true)
        .overlay {
            if presenter.isAdminActionLoading {
                ProgressView()
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var adminActionsSection: some View {
        VStack(spacing: 10) {
            AppButton(
                title: AppTextExamDetail.adminReassignPicButton,
                leftIcon: AppIcon.personFill,
                colorType: .secondary,
                size: .small,
                isEnabled: !presenter.isObservationArchived
            ) {
                showPICPicker = true
            }

            if presenter.isObservationArchived {
                AppButton(
                    title: AppTextExamDetail.adminRestoreButton,
                    colorType: .secondary,
                    size: .small
                ) {
                    Task {
                        _ = await presenter.adminSetArchived(observationId: examId, archived: false)
                    }
                }
            } else {
                AppButton(
                    title: AppTextExamDetail.adminArchiveButton,
                    colorType: .destructive(.secondary),
                    size: .small
                ) {
                    showArchiveConfirm = true
                }
            }

            AppButton(
                title: AppTextExamDetail.adminExportCsvButton,
                leftIcon: AppIcon.share,
                colorType: .secondary,
                size: .small
            ) {
                Task {
                    let filters = HistoryExamFilters.defaultRange()
                    if let url = await presenter.exportFacilityCsv(filters: filters) {
                        csvShareURL = url
                        showCsvShare = true
                    }
                }
            }
        }
    }
}

private struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ExamDetailAdminView(examId: "6f4e5288-3dfd-4be4-8a2e-8c60f09f07e2", patientId: "d0c1a2b3-4f5e-6789-91ab-cdef12345678")
}
