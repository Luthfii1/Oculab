//
//  PatientFormView.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 08/11/24.
//

import SwiftUI

struct PatientFormView: View {
    let patientId: String?
    @State private var presenter = PatientPresenter()
    
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
                        title: isAddingNewPatient ? AppTextPatientCompCard.buttonCreatePatient : AppTextPatientCompCard.buttonSavePatient,
                        leftIcon: isAddingNewPatient ? AppIcon.add : AppIcon.checkmark,
                        isEnabled: presenter.isFormValid
                    ) {
                        Task {
                            if isAddingNewPatient {
                                await presenter.addNewPatientWithValidation()
                            } else {
                                await presenter.updatePatientWithValidation()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Decimal.d20)
            .padding(.vertical, Decimal.d24)
            .navigationTitle(isAddingNewPatient ? AppTextPatientForm.newPatientNavigationTitle : AppTextPatientForm.editPatientNavigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Router.shared.navigateBack()
                    }) {
                        HStack {
                            Image(AppImage.back)
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
            .alert(AppValue.unknownError, isPresented: .constant(presenter.errorMessage != nil)) {
                Button(AppAction.ok) {
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

#Preview("Edit Patient") {
    PatientFormView(patientId: "d0c1a2b3-4f5e-6789-91ab-cdef12345678")
}
