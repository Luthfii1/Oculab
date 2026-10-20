import SwiftUI

struct PatientDetailView: View {
    let patientId: String
    @State private var presenter = PatientPresenter()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let error = presenter.patientLoadErrorMessage {
                        PatientLoadErrorView(title: AppTextPatientIntake.patientLoadFailed, message: error) {
                            Task { await presenter.getPatientById(patientId: patientId) }
                        }
                    }
                    if presenter.isPatientLoading && !presenter.hasLoadedEditingPatient {
                        ProgressView(AppTextPatientDetail.loadingPatientMessage)
                            .frame(maxWidth: .infinity, minHeight: 180)
                    } else if presenter.hasLoadedEditingPatient {
                        AppCard(icon: AppIcon.personFill, title: AppTextPatientDetail.patientDataTitle, spacing: 16, isEnablingEdit: true) {
                            ExtendedCard(data: [
                                (AppPatient.name, presenter.patient.name),
                                (AppTextPatientIntake.medicalRecordNumber, present(presenter.patient.medicalRecordNumber)),
                                (AppPatient.nik, present(presenter.patient.NIK)),
                                (AppPatient.dateOfBirth, presenter.formatDate(presenter.patient.DoB)),
                                (AppPatient.gender, present(presenter.selectedSex)),
                                (AppPatient.bpjsNumber, present(presenter.patient.BPJS)),
                            ], titleSize: AppTypography.s5)
                        } action: { presenter.navigateTo(.patientForm(patientId: patientId)) }

                        AppCard(icon: AppIcon.textBadgeCheckmark, title: AppTextPatientDetail.examinationResultTitle, spacing: 16, isBorderDisabled: true) {
                            AppButton(title: AppTextPatientDetail.buttonCreateExamination, leftIcon: AppIcon.docBadgePlus) {
                                presenter.navigateTo(.inputPatientData(patientId: patientId))
                            }
                            if let error = presenter.examinationsErrorMessage {
                                PatientLoadErrorView(title: AppTextPatientIntake.examinationsLoadFailed, message: error) {
                                    Task { await presenter.getExaminationsByPatientId(patientId: patientId) }
                                }
                            }
                            if presenter.isLoadingExaminations && presenter.examinationList.isEmpty {
                                ProgressView(AppTextPatientDetail.loadingExaminationsMessage)
                            } else if presenter.hasLoadedExaminations && presenter.examinationList.isEmpty && presenter.examinationsErrorMessage == nil {
                                Text(AppTextPatientDetail.noExaminationsMessage).foregroundStyle(.secondary)
                            }
                            ForEach(presenter.examinationList) { examination in
                                Button {
                                    Router.shared.navigateTo(.examDetailAdmin(examId: examination.id, patientId: patientId))
                                } label: {
                                    HomeActivityComponent(slideId: examination.slideId, status: examination.statusExamination,
                                                          date: presenter.formatDateTime(examination.examinationDate),
                                                          patientName: examination.patientName, patientDOB: presenter.formatDate(examination.patientDob),
                                                          picName: examination.dpjpName ?? AppTextPatientDetail.notDeterminedMessage,
                                                          viewType: .adminPatientDetail)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 20)
            }
            .padding(.horizontal, 20)
            .navigationTitle(AppTextPatientDetail.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { presenter.navigateBack() } label: { Image(AppImage.back) }
                }
            }
            .task {
                async let patientLoad: Void = presenter.getPatientById(patientId: patientId)
                async let examinationLoad: Void = presenter.getExaminationsByPatientId(patientId: patientId)
                _ = await (patientLoad, examinationLoad)
            }
            .onDisappear { presenter.resetState() }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func present(_ value: String?) -> String {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return AppTextPatientIntake.missingValue }
        return value
    }
}
