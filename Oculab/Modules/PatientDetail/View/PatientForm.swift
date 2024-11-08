//
//  PatientForm.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 08/11/24.
//

import SwiftUI

struct PatientForm: View {
    var isAddingNewPatient: Bool

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: Decimal.d24) {
                        PatientFormField(
                            isAddingNewPatient: isAddingNewPatient,
                            isAddingName: true,
                            presenter: InputPatientPresenter()
                        )
                    }
                }

                Spacer()

                AppButton(
                    title: isAddingNewPatient ? "Tambahkan Pasien Baru" : "Simpan Data Pasien",
                    leftIcon: isAddingNewPatient ? "plus" : "",
                    rightIcon: isAddingNewPatient ? "" : "checkmark"
                ) {}
            }

            .padding(.horizontal, Decimal.d20)
            .padding(.vertical, Decimal.d24)
            .navigationTitle(isAddingNewPatient ? "Data Pasien Baru" : "Ubah Data Pasien")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        //                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image("back")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    PatientForm(isAddingNewPatient: true)
}
