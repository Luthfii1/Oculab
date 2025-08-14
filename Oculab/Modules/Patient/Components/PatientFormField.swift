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
        VStack(alignment: .leading, spacing: 24) {
            ValidatedTextField(
                title: AppPatient.name,
                isRequired: true,
                placeholder: AppTextPatientCompFormField.namePlaceholder,
                leftIcon: AppIcon.personFill,
                text: $presenter.patient.name,
                fieldName: .patientName
            )
            
            ValidatedTextField(
                title: AppPatient.nik,
                isRequired: true,
                placeholder: AppPatient.Placeholder.nik,
                isNumberOnly: true,
                length: 16,
                text: $presenter.patient.NIK,
                fieldName: .patientNIK
            )

            DateField(
                title: AppPatient.dateOfBirth,
                isRequired: true,
                placeholder: AppPatient.Placeholder.selectDate,
                rightIcon: AppIcon.calendar,
                date: $presenter.selectedDoB
            )
            .onChange(of: presenter.selectedDoB) {
                presenter.patient.DoB = presenter.selectedDoB
            }

            AppRadioButton(
                title: AppPatient.gender,
                isRequired: true,
                choices: [AppPatient.Gender.female, AppPatient.Gender.male],
                isDisabled: false,
                selectedChoice: $presenter.selectedSex
            )
            .onChange(of: presenter.selectedSex) {
                switch presenter.selectedSex {
                case AppPatient.Gender.female:
                    presenter.patient.sex = .FEMALE
                case AppPatient.Gender.male:
                    presenter.patient.sex = .MALE
                default:
                    presenter.patient.sex = .UNKNOWN
                }
            }

            ValidatedTextField(
                title: AppPatient.bpjsNumber,
                placeholder: AppPatient.Placeholder.bpjs,
                isNumberOnly: true,
                length: 13,
                text: $presenter.BPJSnumber,
                fieldName: .patientBPJS
            )
            .onChange(of: presenter.BPJSnumber) {
                presenter.patient.BPJS = presenter.BPJSnumber.isEmpty ? nil : presenter.BPJSnumber
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(AppAction.done) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }
}

#Preview {
    PatientFormField(presenter: PatientPresenter())
}
