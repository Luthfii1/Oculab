//
//  PatientFormField.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 08/11/24.
//

import SwiftUI

struct PatientFormField: View {
    @State var isAddingNewPatient: Bool
    @State var isAddingName: Bool

    @ObservedObject var presenter: InputPatientPresenter

    var body: some View {
        if isAddingName {
            AppTextField(
                title: "Nama",
                placeholder: "Contoh: Alya Annisa Kirana",
                leftIcon: "person.fill",
                isDisabled: !isAddingNewPatient,
                text: $presenter.patient.name
            )
        }

        AppTextField(
            title: "NIK",
            placeholder: "Contoh: 167012039484700",
            isDisabled: !isAddingNewPatient,
            text: $presenter.patient.NIK
        )

        DateField(
            title: "Tanggal Lahir",
            placeholder: "Pilih Tanggal",
            rightIcon: "calendar",
            isDisabled: !isAddingNewPatient,
            date: Binding(
                get: { presenter.patient.DoB ?? Date() },
                set: { presenter.patient.DoB = $0 }
            )
        )

        AppRadioButton(
            title: "Jenis Kelamin", isRequired: true,
            choices: ["Perempuan", "Laki-laki"],
            selectedChoice: Binding(
                get: { presenter.patient.sex.rawValue },
                set: { presenter.patient.sex = SexType(rawValue: $0) ?? .MALE }
            )
        )

        AppTextField(
            title: "Nomor BPJS (opsional)",
            placeholder: "Contoh: 06L30077675",
            isDisabled: !isAddingNewPatient,
            text: Binding(
                get: { presenter.patient.BPJS ?? "" },
                set: { presenter.patient.BPJS = $0.isEmpty ? nil : $0 }
            )
        )
    }
}

#Preview {
    PatientFormField(isAddingNewPatient: true, isAddingName: false, presenter: InputPatientPresenter())
}
