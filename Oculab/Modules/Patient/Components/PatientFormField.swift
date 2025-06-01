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
                title: "Nama",
                isRequired: true,
                placeholder: "John Doe",
                leftIcon: "person.fill",
                text: $presenter.patient.name
            )
            
            AppTextField(
                title: "NIK",
                isRequired: true,
                placeholder: "Contoh: 167012039484700",
                isNumberOnly: true,
                length: 16,
                text: $presenter.patient.NIK
            )

            DateField(
                title: "Tanggal Lahir",
                isRequired: true,
                placeholder: "Pilih Tanggal",
                rightIcon: "calendar",
                date: $presenter.selectedDoB
            )
            .onChange(of: presenter.selectedDoB) {
                presenter.patient.DoB = presenter.selectedDoB
            }

            AppRadioButton(
                title: "Jenis Kelamin",
                isRequired: true,
                choices: ["Perempuan", "Laki-laki"],
                isDisabled: false,
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
                Button("Selesai") {
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
