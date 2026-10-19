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
        [ValidationFieldName.patientNIK, .patientDateOfBirth, .patientGender, .patientBPJS]
            .contains { presenter.validationManager.getError(for: $0.fieldName) != nil }
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
            ValidatedTextField(
                title: AppPatient.nik,
                isRequired: true,
                placeholder: AppPatient.Placeholder.nik,
                isDisabled: false,
                isNumberOnly: true,
                length: 16,
                text: $presenter.patient.NIK,
                fieldName: .patientNIK,
                validationType: .nik,
                validationManager: presenter.validationManager
            )
            .onChange(of: presenter.patient.NIK) { _, _ in
                presenter.handleNIKChange()
            }

            DateField(
                title: AppPatient.dateOfBirth,
                isRequired: true,
                placeholder: AppPatient.Placeholder.selectDate,
                rightIcon: AppIcon.calendar,
                isDisabled: false,
                date: $presenter.selectedDoB
            )
            .onChange(of: presenter.selectedDoB) {
                guard !presenter.patientFound else { return }
                presenter.handleDateOfBirthChange()
            }

            AppRadioButton(
                title: AppPatient.gender,
                isRequired: true,
                choices: [AppPatient.Gender.female, AppPatient.Gender.male],
                isDisabled: false,
                selectedChoice: $presenter.selectedSex
            )
            .onChange(of: presenter.selectedSex) {
                presenter.handleGenderChange()
            }

            ValidationFieldErrorView(
                fieldName: ValidationFieldName.patientGender.fieldName,
                showsErrors: true,
                validationManager: presenter.validationManager
            )

            ValidatedTextField(
                title: AppPatient.bpjsNumber + " " + AppForm.optional,
                placeholder: AppPatient.Placeholder.bpjs,
                isDisabled: false,
                length: 13,
                text: $presenter.BPJSnumber,
                fieldName: .patientBPJS,
                validationType: .bpjs,
                validationManager: presenter.validationManager
            )
            .onChange(of: presenter.BPJSnumber) {
                presenter.handleBPJSNumberChange()
            }
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
