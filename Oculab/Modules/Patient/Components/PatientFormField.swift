//
//  PatientFormField.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 08/11/24.
//

import SwiftUI

struct PatientFormField: View {
    @EnvironmentObject var presenter: PatientPresenter

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            AppTextField(
                title: AppTextPatientCompFormField.nameTitle,
                isRequired: true,
                placeholder: AppTextPatientCompFormField.namePlaceholder,
                leftIcon: AppText.Icon.personFill,
                text: $presenter.patient.name
            )
            
            AppTextField(
                title: AppTextPatientCompFormField.nikTitle,
                isRequired: true,
                placeholder: AppTextPatientCompFormField.nikPlaceholder,
                isNumberOnly: true,
                length: 16,
                text: $presenter.patient.NIK
            )

            DateField(
                title: AppTextPatientCompFormField.birthDateTitle,
                isRequired: true,
                placeholder: AppTextPatientCompFormField.birthDatePlaceholder,
                rightIcon: AppText.Icon.calendar,
                date: $presenter.selectedDoB
            )
            .onChange(of: presenter.selectedDoB) {
                presenter.patient.DoB = presenter.selectedDoB
            }

            AppRadioButton(
                title: AppTextPatientCompFormField.genderTitle,
                isRequired: true,
                choices: [AppTextPatientCompFormField.femaleChoice, AppTextPatientCompFormField.maleChoice],
                isDisabled: false,
                selectedChoice: $presenter.selectedSex
            )
            .onChange(of: presenter.selectedSex) {
                switch presenter.selectedSex {
                case AppTextPatientCompFormField.femaleChoice:
                    presenter.patient.sex = .FEMALE
                case AppTextPatientCompFormField.maleChoice:
                    presenter.patient.sex = .MALE
                default:
                    presenter.patient.sex = .UNKNOWN
                }
            }

            AppTextField(
                title: AppTextPatientCompFormField.bpjsTitle,
                placeholder: AppTextPatientCompFormField.bpjsPlaceholder,
                isNumberOnly: true,
                length: 13,
                text: $presenter.BPJSnumber
            )
            .onChange(of: presenter.BPJSnumber) {
                presenter.patient.BPJS = presenter.BPJSnumber.isEmpty ? nil : presenter.BPJSnumber
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(AppTextPatientCompFormField.doneButton) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }
}

#Preview {
    PatientFormField()
        .environmentObject(PatientPresenter())
}
