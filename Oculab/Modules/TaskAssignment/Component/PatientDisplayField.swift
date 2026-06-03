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
        VStack(alignment: .leading, spacing: 24) {
            patientDetailsHeader

            if presenter.isPatientLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text(AppTextTaskAssignInputPatient.loadingDataMessage)
                        .font(AppTypography.p3)
                        .foregroundColor(AppColors.slate400)
                }
            }

            ValidatedTextField(
                title: AppPatient.nik,
                isRequired: true,
                placeholder: AppPatient.Placeholder.nik,
                isDisabled: presenter.patientFound,
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
                rightIcon: presenter.patientFound ? nil : AppIcon.calendar,
                isDisabled: presenter.patientFound,
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
                isDisabled: presenter.patientFound,
                selectedChoice: $presenter.selectedSex
            )
            .onChange(of: presenter.selectedSex) {
                presenter.handleGenderChange()
            }

            ValidatedTextField(
                title: AppPatient.bpjsNumber,
                placeholder: AppPatient.Placeholder.bpjs,
                isDisabled: presenter.patientFound,
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
        .opacity(presenter.isPatientLoading ? 0.6 : 1)
        .allowsHitTesting(!presenter.isPatientLoading)
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
