//
//  PatientFormField.swift
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

struct PatientFormField: View {
    @EnvironmentObject var presenter: InputPatientPresenter
    @FocusState var focusedField: FormField?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            AppTextField(
                title: "NIK",
                isRequired: true,
                placeholder: "Contoh: 167012039484700",
                isDisabled: presenter.patientFound,
                isNumberOnly: true,
                length: 16,
                text: $presenter.patient.NIK
            )
            .focused($focusedField, equals: .nik)

            DateField(
                title: "Tanggal Lahir",
                isRequired: true,
                placeholder: "Pilih Tanggal",
                rightIcon: "calendar",
                isDisabled: presenter.patientFound,
                date: $presenter.selectedDoB
            )
            .onChange(of: presenter.selectedDoB) {
                presenter.patient.DoB = presenter.selectedDoB
            }

            AppRadioButton(
                title: "Jenis Kelamin",
                isRequired: true,
                choices: ["Perempuan", "Laki-laki"],
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
                title: "Nomor BPJS (opsional)",
                placeholder: "Contoh: 1240630077675",
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
                Button("Selesai") {
                    focusedField = nil
                }
            }
        }
    }
}

#Preview {
    PatientFormField()
        .environmentObject(InputPatientPresenter())
}
