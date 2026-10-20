import SwiftUI

struct PatientFormView: View {
    let patientId: String?
    @State private var presenter = PatientPresenter()
    init(patientId: String? = nil) { self.patientId = patientId }

    var body: some View {
        NavigationView {
            Group {
                if presenter.isPatientLoading && !presenter.hasLoadedEditingPatient {
                    ProgressView(AppTextPatientIntake.loadingPatient)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = presenter.patientLoadErrorMessage {
                    PatientLoadErrorView(title: AppTextPatientIntake.patientLoadFailed, message: error) {
                        Task { await presenter.retryPatientLoad() }
                    }
                } else {
                    ScrollView {
                        PatientFormField(presenter: presenter)
                            .padding(.horizontal, 20).padding(.vertical, 24)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        VStack(alignment: .leading, spacing: 10) {
                            if let error = presenter.errorMessage {
                                Label(error, systemImage: "exclamationmark.circle")
                                    .font(.subheadline).foregroundStyle(AppColors.red700)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            AppButton(title: presenter.isSavingPatient ? AppTextPatientIntake.savingPatient : presenter.buttonTitle,
                                      leftIcon: presenter.buttonIcon, isEnabled: presenter.canSubmit,
                                      isLoading: presenter.isSavingPatient) {
                                presenter.dismissKeyboard()
                                Task { await presenter.handleFormSubmission() }
                            }
                            .accessibilityIdentifier("patient.save")
                        }
                        .padding(16).background(.regularMaterial)
                        .overlay(alignment: .top) { Divider() }
                    }
                }
            }
            .navigationTitle(presenter.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { Router.shared.navigateBack() } label: { Image(AppImage.back) }
                }
            }
            .onAppear { presenter.setupForm(patientId: patientId) }
            .onDisappear { presenter.resetState() }
        }
        .navigationBarBackButtonHidden(true)
    }
}

/// Explicit recovery for request failures. Empty success states remain separate.
struct PatientLoadErrorView: View {
    let title: String
    let message: String
    var retry: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "exclamationmark.triangle").font(.headline)
            Text(message).font(.subheadline).foregroundStyle(.secondary)
            Button(AppAction.retry, action: retry).buttonStyle(.bordered)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.slate50).clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.vertical, 12)
    }
}
