//
//  PatientFormField.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 08/11/24.
//

import SwiftUI

struct PatientFormField: View {
    @State var isAddingName: Bool

    @State var selectedSex: String = ""
    @State var selectedDoB: Date = .init()
    @State var BPJSnumber: String = ""

    @ObservedObject var presenter: InputPatientPresenter

    var body: some View {
        if !presenter.patientFound {
            AppTextField(
                title: "Nama",
                placeholder: "Contoh: Alya Annisa Kirana",
                leftIcon: "person.fill",
                isDisabled: presenter.patientFound,
                text: $presenter.patient.name
            )
        }

        AppTextField(
            title: "NIK",
            placeholder: "Contoh: 167012039484700",
            isDisabled: presenter.patientFound,
            isNumberOnly: true,
            length: 16,
            text: $presenter.patient.NIK
        )

        DateField(
            title: "Tanggal Lahir",
            placeholder: "Pilih Tanggal",
            rightIcon: "calendar",
            isDisabled: presenter.patientFound,
            date: $selectedDoB
        ).onChange(of: selectedDoB) {
            presenter.patient.DoB = selectedDoB
        }

        AppRadioButton(
            title: "Jenis Kelamin", isRequired: true,
            choices: ["Perempuan", "Laki-laki"],
            isDisabled: presenter.patientFound,
            selectedChoice: $selectedSex
        )
        .onChange(of: selectedSex) {
            switch selectedSex {
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
            text: $BPJSnumber

        ).onChange(of: BPJSnumber) {
            presenter.patient.BPJS = BPJSnumber
        }
    }
}

#Preview {
    PatientFormField(isAddingName: false, presenter: InputPatientPresenter())
}
