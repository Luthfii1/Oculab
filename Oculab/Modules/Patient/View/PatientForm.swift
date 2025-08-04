//
//  PatientForm.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 08/11/24.
//

import SwiftUI

struct PatientForm: View {
    let patientId: String?
    @StateObject private var presenter = PatientPresenter()
    
    private var isAddingNewPatient: Bool {
        patientId == nil
    }

    init(patientId: String? = nil) {
        self.patientId = patientId
    }

    var body: some View {
        NavigationView {
            VStack {
                if presenter.isPatientLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Decimal.d24) {
                            PatientFormField()
                                .environmentObject(presenter)
                        }
                    }

                    Spacer()

                    AppButton(
                        title: isAddingNewPatient ? AppText.Patient.Form.addNewPatientButton : AppText.Patient.Form.savePatientButton,
                        leftIcon: isAddingNewPatient ? AppText.Icon.plus : AppText.Icon.checkmark
                    ) {
                        Task {
                            if isAddingNewPatient {
                                await presenter.addNewPatient()
                            } else {
                                await presenter.updatePatient()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Decimal.d20)
            .padding(.vertical, Decimal.d24)
            .navigationTitle(isAddingNewPatient ? AppText.Patient.Form.newPatientNavigationTitle : AppText.Patient.Form.editPatientNavigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Router.shared.navigateBack()
                    }) {
                        HStack {
                            Image(AppText.Icon.back)
                        }
                    }
                }
            }
            .onAppear {
                if let patientId = patientId {
                    Task {
                        await presenter.getPatientById(patientId: patientId)
                    }
                }
            }
            .alert(AppText.Common.errorAlertTitle, isPresented: .constant(presenter.errorMessage != nil)) {
                Button(AppText.Common.okButton) {
                    presenter.errorMessage = nil
                }
            } message: {
                if let errorMessage = presenter.errorMessage {
                    Text(errorMessage)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    PatientForm()
}

#Preview("Edit Patient") {
    PatientForm(patientId: "d0c1a2b3-4f5e-6789-91ab-cdef12345678")
}
