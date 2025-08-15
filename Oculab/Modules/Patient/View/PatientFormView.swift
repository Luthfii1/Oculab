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
                        VStack(alignment: .leading, spacing: AppConstants.PatientUI.fieldSpacing) {
                            PatientFormField(presenter: presenter)
                        }
                    }

                    Spacer()

                    AppButton(
                        title: presenter.buttonTitle,
                        leftIcon: presenter.buttonIcon,
                        isEnabled: presenter.isFormValid
                    ) {
                        Task {
                            await presenter.handleFormSubmission()
                        }
                    }
                }
            }
            .padding(.horizontal, AppConstants.PatientUI.horizontalPadding)
            .padding(.vertical, AppConstants.PatientUI.fieldSpacing)
            .navigationTitle(presenter.navigationTitle)
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
                presenter.setupForm(patientId: patientId)
            }
            .alert(AppValue.unknownError, isPresented: Binding(
                get: { presenter.errorMessage != nil },
                set: { _ in presenter.errorMessage = nil }
            )) {
                Button(AppAction.ok) { }
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
