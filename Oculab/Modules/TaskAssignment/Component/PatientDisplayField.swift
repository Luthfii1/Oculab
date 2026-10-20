//
//  PatientDisplayField.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 08/11/24.
//

import SwiftUI

struct PatientDisplayField: View {
    @EnvironmentObject var presenter: TaskAssignmentFlowCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if presenter.isPatientLoading {
                ProgressView(AppTextTaskAssignInputPatient.loadingDataMessage)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                patientDetailsHeader
                if presenter.patientFound {
                    existingPatientSummary
                } else {
                    Text("task_assignment.ux.new_patient_hint".localized)
                        .font(AppTypography.p3)
                        .foregroundStyle(AppColors.slate600)
                    newPatientFields
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.slate0)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.slate200, lineWidth: 1)
        }
    }

    private var existingPatientSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let recordNumber = presenter.patient.medicalRecordNumber, !recordNumber.isEmpty {
                summaryRow(AppTextPatientIntake.medicalRecordNumber, value: recordNumber)
            }
            intakeFieldError(.medicalRecordNumber)
            summaryRow(AppPatient.nik, value: presenter.patient.NIK)
            storedFieldError(.patientNIK)
            summaryRow(AppPatient.dateOfBirth, value: presenter.patient.DoB?.formattedDDMMYYYY() ?? AppValue.defaultStrike)
            storedFieldError(.patientDateOfBirth)
            summaryRow(AppPatient.gender, value: presenter.selectedSex)
            storedFieldError(.patientGender)
            if let bpjs = presenter.patient.BPJS, !bpjs.isEmpty {
                summaryRow(AppPatient.bpjsNumber, value: bpjs)
            }
            storedFieldError(.patientBPJS)
            if hasStoredFieldErrors {
                Text("task_assignment.ux.correct_patient_hint".localized)
                    .font(AppTypography.p3)
                    .foregroundStyle(AppColors.red700)
                    .fixedSize(horizontal: false, vertical: true)
                AppButton(
                    title: "task_assignment.ux.edit_patient".localized,
                    colorType: .secondary,
                    size: .small
                ) {
                    Router.shared.navigateTo(.patientForm(patientId: presenter.patient.id))
                }
            }
            Label("task_assignment.ux.existing_patient_hint".localized, systemImage: "checkmark.shield")
                .font(AppTypography.p3)
                .foregroundStyle(AppColors.slate600)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
    }

    private var hasStoredFieldErrors: Bool {
        PatientIntakeField.allCases.contains { presenter.validationManager.getError(for: $0.validationKey) != nil }
    }

    private func storedFieldError(_ field: ValidationFieldName) -> some View {
        ValidationFieldErrorView(
            fieldName: field.fieldName,
            showsErrors: true,
            validationManager: presenter.validationManager
        )
    }

    private func summaryRow(_ label: String, value: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                Text(label).foregroundStyle(AppColors.slate600)
                Spacer(minLength: 20)
                Text(value.isEmpty ? AppValue.defaultStrike : value).foregroundStyle(AppColors.slate900)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(label).foregroundStyle(AppColors.slate600)
                Text(value.isEmpty ? AppValue.defaultStrike : value).foregroundStyle(AppColors.slate900)
            }
        }
        .font(AppTypography.p3)
        .accessibilityElement(children: .combine)
    }

    private var newPatientFields: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(AppTextPatientIntake.requiredHint).font(.subheadline).foregroundStyle(.secondary)
            PatientBirthDateField(date: $presenter.selectedDoB)
                .onChange(of: presenter.selectedDoB) {
                    guard !presenter.patientFound else { return }
                    presenter.handleDateOfBirthChange()
                }
            intakeFieldError(.dateOfBirth)
            AppRadioButton(title: AppPatient.gender, isRequired: true,
                           choices: [AppPatient.Gender.female, AppPatient.Gender.male],
                           isDisabled: false, selectedChoice: $presenter.selectedSex)
                .onChange(of: presenter.selectedSex) { presenter.handleGenderChange() }
            intakeFieldError(.sex)
            Divider()
            Text(AppTextPatientIntake.identifiersTitle).font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            Text(AppTextPatientIntake.identifiersHint).font(.subheadline).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            optionalIdentifier(AppTextPatientIntake.medicalRecordNumber, placeholder: AppTextPatientIntake.medicalRecordPlaceholder,
                               text: Binding(get: { presenter.patient.medicalRecordNumber ?? "" }, set: {
                                   presenter.patient.medicalRecordNumber = $0
                                   presenter.handleMedicalRecordNumberChange()
                               }), field: .medicalRecordNumber)
            optionalIdentifier(AppPatient.nik, placeholder: AppPatient.Placeholder.nik,
                               text: Binding(get: { presenter.patient.NIK }, set: {
                                   presenter.patient.NIK = $0
                                   presenter.handleNIKChange()
                               }), field: .nik, numeric: true)
            optionalIdentifier(AppPatient.bpjsNumber, placeholder: AppPatient.Placeholder.bpjs,
                               text: Binding(get: { presenter.BPJSnumber }, set: {
                                   presenter.BPJSnumber = $0
                                   presenter.handleBPJSNumberChange()
                               }), field: .bpjs, numeric: true)
        }
    }

    private func optionalIdentifier(_ title: String, placeholder: String, text: Binding<String>, field: PatientIntakeField, numeric: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(AppForm.optional).font(.caption).foregroundStyle(.secondary)
            }
            TextField(placeholder, text: text)
                .keyboardType(numeric ? .numberPad : .default)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .padding(12).background(AppColors.slate0)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay { RoundedRectangle(cornerRadius: 8).stroke(AppColors.slate300) }
                .accessibilityLabel(title)
            intakeFieldError(field)
        }
    }

    @ViewBuilder
    private func intakeFieldError(_ field: PatientIntakeField) -> some View {
        if let message = presenter.validationManager.getError(for: field.validationKey) {
            Label(message, systemImage: "exclamationmark.circle")
                .font(.caption).foregroundStyle(AppColors.red700)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var patientDetailsHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppTextTaskAssignInputPatient.patientDetailsSectionTitle)
                .font(AppTypography.s4_1)
                .foregroundColor(AppColors.slate900)

            Text(presenter.selectedPatientDisplayName)
                .font(AppTypography.h3)
                .foregroundColor(AppColors.slate900)

            HStack(spacing: 6) {
                Image(systemName: presenter.patientFound ? AppIcon.textBadgeCheckmark : AppIcon.personFill)
                    .font(.caption)
                Text(
                    presenter.patientFound
                        ? AppTextTaskAssignInputPatient.existingPatientBadge
                        : AppTextTaskAssignInputPatient.newPatientBadge
                )
                .font(AppTypography.p3)
            }
            .foregroundColor(presenter.patientFound ? AppColors.purple700 : AppColors.slate400)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(AppColors.purple50)
            .cornerRadius(8)
        }
    }
}

#Preview {
    PatientDisplayField()
        .environmentObject(TaskAssignmentFlowCoordinator())
}
