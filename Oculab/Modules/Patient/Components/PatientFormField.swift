//
//  PatientFormField.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 08/11/24.
//

import SwiftUI

struct PatientFormField: View {
    @Bindable var presenter: PatientPresenter

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.PatientUI.fieldSpacing) {
            ValidatedTextField(
                title: AppPatient.name,
                isRequired: true,
                placeholder: AppTextPatientCompFormField.namePlaceholder,
                leftIcon: AppIcon.personFill,
                text: $presenter.patient.name,
                fieldName: .patientName
            )
            .onChange(of: presenter.patient.name) {
                presenter.handleNameChange()
            }

            ValidatedTextField(
                title: AppPatient.nik,
                isRequired: true,
                placeholder: AppPatient.Placeholder.nik,
                isNumberOnly: true,
                length: AppConstants.PatientUI.nikLength,
                text: $presenter.patient.NIK,
                fieldName: .patientNIK
            )
            .onChange(of: presenter.patient.NIK) {
                presenter.handleNIKChange()
            }

            DateField(
                title: AppPatient.dateOfBirth,
                isRequired: true,
                placeholder: AppPatient.Placeholder.selectDate,
                rightIcon: AppIcon.calendar,
                date: $presenter.selectedDoB
            )
            .onChange(of: presenter.selectedDoB) {
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

            ValidatedTextField(
                title: AppPatient.bpjsNumber,
                placeholder: AppPatient.Placeholder.bpjs,
                isNumberOnly: true,
                length: AppConstants.PatientUI.bpjsLength,
                text: $presenter.BPJSnumber,
                fieldName: .patientBPJS
            )
            .onChange(of: presenter.BPJSnumber) {
                presenter.handleBPJSChange()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(AppAction.done) {
                    presenter.dismissKeyboard()
                }
            }
        }
    }
}

#Preview {
    PatientFormField(presenter: PatientPresenter())
}
