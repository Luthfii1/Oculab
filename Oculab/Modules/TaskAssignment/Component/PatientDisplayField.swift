//
//  PatientDisplayField.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 08/11/24.
//

import SwiftUI

struct PatientDisplayField: View {
    @EnvironmentObject var presenter: InputPatientPresenter

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ValidatedTextField(
                title: AppPatient.nik,
                isRequired: true,
                placeholder: AppPatient.Placeholder.nik,
                isDisabled: presenter.patientFound,
                isNumberOnly: true,
                length: 16,
                text: $presenter.patient.NIK,
                fieldName: .patientNIK,
                validationType: .nik
            )

            DateField(
                title: AppPatient.dateOfBirth,
                isRequired: true,
                placeholder: AppPatient.Placeholder.selectDate,
                rightIcon: AppIcon.calendar,
                isDisabled: presenter.patientFound,
                date: $presenter.selectedDoB
            )
            .onChange(of: presenter.selectedDoB) {
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
                text: $presenter.BPJSnumber,
                fieldName: .patientBPJS,
                validationType: .bpjs
            )
            .onChange(of: presenter.BPJSnumber) {
                presenter.handleBPJSNumberChange()
            }
        }
    }
}

#Preview {
    PatientDisplayField()
        .environmentObject(InputPatientPresenter())
}
