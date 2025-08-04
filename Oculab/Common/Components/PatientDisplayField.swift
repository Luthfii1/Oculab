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
            AppTextField(
                title: AppTextTaskAssignCompPatientDisplay.nikTitle,
                isRequired: true,
                placeholder: AppTextTaskAssignCompPatientDisplay.nikPlaceholder,
                isDisabled: presenter.patientFound,
                isNumberOnly: true,
                length: 16,
                text: $presenter.patient.NIK
            )
            .focused($focusedField, equals: .nik)

            DateField(
                title: AppTextTaskAssignCompPatientDisplay.birthDateTitle,
                isRequired: true,
                placeholder: AppTextTaskAssignCompPatientDisplay.birthDatePlaceholder,
                rightIcon: "calendar",
                isDisabled: presenter.patientFound,
                date: $presenter.selectedDoB
            )
            .onChange(of: presenter.selectedDoB) {
                presenter.patient.DoB = presenter.selectedDoB
            }

            AppRadioButton(
                title: AppTextTaskAssignCompPatientDisplay.genderTitle,
                isRequired: true,
                choices: [AppTextTaskAssignCompPatientDisplay.femaleChoice, AppTextTaskAssignCompPatientDisplay.maleChoice],
                isDisabled: presenter.patientFound,
                selectedChoice: $presenter.selectedSex
            )
            .onChange(of: presenter.selectedSex) {
                switch presenter.selectedSex {
                case "Perempuan":
                    presenter.patient.sex = .FEMALE
                case "Laki-laki":
                    presenter.patient.sex = .MALE
                default:
                    presenter.patient.sex = .UNKNOWN
                }
            }

            AppTextField(
                title: AppTextTaskAssignCompPatientDisplay.bpjsTitle,
                placeholder: AppTextTaskAssignCompPatientDisplay.bpjsPlaceholder,
                isDisabled: presenter.patientFound,
                isNumberOnly: true,
                length: 13,
                text: $presenter.BPJSnumber
            )
            .focused($focusedField, equals: .bpjs)
            .onChange(of: presenter.BPJSnumber) {
                presenter.patient.BPJS = presenter.BPJSnumber
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(AppTextTaskAssignCompPatientDisplay.doneButton) {
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
