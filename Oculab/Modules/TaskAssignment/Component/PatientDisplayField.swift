//
//  PatientDisplayField.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 08/11/24.
//

import SwiftUI

enum FormField {
    case search
    case nik
    case bpjs
}

struct PatientDisplayField: View {
    @EnvironmentObject var presenter: InputPatientPresenter
    @FocusState var focusedField: FormField?

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
            .focused($focusedField, equals: .nik)

            DateField(
                title: AppPatient.dateOfBirth,
                isRequired: true,
                placeholder: AppPatient.Placeholder.selectDate,
                rightIcon: AppIcon.calendar,
                isDisabled: presenter.patientFound,
                date: $presenter.selectedDoB
            )
            .onChange(of: presenter.selectedDoB) {
                presenter.patient.DoB = presenter.selectedDoB
            }

            AppRadioButton(
                title: AppPatient.gender,
                isRequired: true,
                choices: [AppPatient.Gender.female, AppPatient.Gender.male],
                isDisabled: presenter.patientFound,
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
                isDisabled: presenter.patientFound,
                text: $presenter.BPJSnumber,
                fieldName: .patientBPJS,
                validationType: .bpjs
            )
            .focused($focusedField, equals: .bpjs)
            .onChange(of: presenter.BPJSnumber) {
                presenter.patient.BPJS = presenter.BPJSnumber
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(AppAction.done) {
                    focusedField = nil
                }
            }
        }
    }
}

#Preview {
    PatientDisplayField()
        .environmentObject(InputPatientPresenter())
}
