import SwiftUI

struct PatientListView: View {
    @State private var presenter = PatientPresenter()

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(AppTextPatientList.navigationTitle).font(.largeTitle.bold())
                    Spacer()
                    CompactNetworkStatusView()
                }
                AppSearchBar(searchText: $presenter.searchText, placeholder: AppTextPatientList.searchPlaceholder,
                             onSearch: { presenter.searchPatients() })
                AppButton(title: AppTextPatientList.buttonCreatePatient, leftIcon: AppIcon.add, colorType: .secondary) {
                    presenter.navigateTo(.patientForm())
                }
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if let error = presenter.listErrorMessage {
                            PatientLoadErrorView(title: AppTextPatientIntake.patientsLoadFailed, message: error) {
                                Task { await presenter.getAllPatient() }
                            }
                        }
                        if presenter.isPatientLoading && presenter.patients.isEmpty {
                            ProgressView().frame(maxWidth: .infinity, minHeight: 180)
                        } else if presenter.isPatientListEmpty {
                            emptyState(AppTextPatientList.emptyListMessage, hint: AppTextPatientList.emptyListHint)
                        } else if !presenter.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && presenter.filteredPatients.isEmpty && !presenter.patients.isEmpty {
                            VStack(spacing: 12) {
                                emptyState(AppSearch.noResults(presenter.searchText))
                                Button(AppSearch.clearSearch) { presenter.clearSearch() }
                            }
                        } else {
                            ForEach(presenter.filteredPatients) { patient in
                                Button { presenter.navigateTo(.patientDetail(patientId: patient.id)) } label: {
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: AppIcon.personFill).foregroundStyle(AppColors.purple700)
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(patient.name).font(.headline).foregroundStyle(AppColors.slate900)
                                            Text(AppPatient.dateOfBirth + ": " + patient.birthDate)
                                                .font(.subheadline).foregroundStyle(.secondary)
                                            if !patient.medicalRecordNumber.isEmpty {
                                                Text(AppTextPatientIntake.medicalRecordNumber + ": " + patient.medicalRecordNumber)
                                                    .font(.caption).foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer(minLength: 0)
                                        Image(systemName: "chevron.right").foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading).padding(16)
                                    .background(AppColors.slate50).clipShape(RoundedRectangle(cornerRadius: 12))
                                    .accessibilityElement(children: .combine)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .refreshable { await presenter.getAllPatient() }
                .scrollDismissesKeyboard(.interactively)
                .overlay(alignment: .topTrailing) {
                    if presenter.isPatientLoading && !presenter.patients.isEmpty { ProgressView().padding(8) }
                }
            }
            .padding(.horizontal, 20)
            .task { await presenter.getAllPatient() }
            .onDisappear { presenter.resetState() }
            .onChange(of: presenter.searchText) { _, _ in presenter.searchPatients() }
        }
        .navigationBarHidden(true)
    }

    private func emptyState(_ message: String, hint: String? = nil) -> some View {
        VStack(spacing: 12) {
            Image(systemName: AppIcon.personFill).font(.largeTitle).foregroundStyle(.secondary)
            Text(message).font(.headline)
            if let hint { Text(hint).font(.subheadline).foregroundStyle(.secondary) }
        }
        .multilineTextAlignment(.center).frame(maxWidth: .infinity, minHeight: 200)
    }
}
