//
//  PatientDetail.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 08/11/24.
//

import SwiftUI

struct PatientDetail: View {
    let patientId: String
    @StateObject private var presenter = PatientPresenter()
    
    var body: some View {
        NavigationView {
            ScrollView {
                if !presenter.isLoadingPatient && !presenter.patient.name.isEmpty {
                    Spacer().frame(height: Decimal.d24)
                    
                    AppCard(icon: AppText.Icon.personFill, title: AppText.Patient.Detail.patientDataTitle, spacing: Decimal.d16, isEnablingEdit: true) {
                        ExtendedCard(data: [
                            (AppText.Patient.Detail.patientNameKey, presenter.patient.name),
                            (AppText.Patient.Detail.patientNikKey, presenter.patient.NIK),
                            (AppText.Patient.Detail.patientDobKey, presenter.formatDate(presenter.patient.DoB)),
                            (AppText.Patient.Detail.patientSexKey, presenter.patient.sex.rawValue),
                            (AppText.Patient.Detail.patientBpjsKey, presenter.patient.BPJS ?? AppText.Common.emptyString),
                        ], titleSize: AppTypography.s5)
                    } action: {
                        presenter.navigateTo(.patientForm(patientId: patientId))
                    }
                    
                    AppCard(
                        icon: AppText.Icon.textBadgeCheckmark,
                        title: AppText.Patient.Detail.examinationResultTitle,
                        spacing: Decimal.d16,
                        isBorderDisabled: true
                    ) {
                        AppButton(title: AppText.Patient.Detail.newExaminationButton, leftIcon: AppText.Icon.docBadgePlusIcon) {
                            presenter.navigateTo(.inputPatientData(patientId: patientId))
                        }
                        
                        if presenter.isLoadingExaminations {
                            ProgressView(AppText.Patient.Detail.loadingExaminationsMessage)
                                .frame(maxWidth: .infinity, minHeight: 60)
                        } else if presenter.examinationList.isEmpty {
                            Text(AppText.Patient.Detail.noExaminationsMessage)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, minHeight: 60)
                        } else {
                            ForEach(presenter.examinationList) { examination in
                                Button {
                                    Router.shared.navigateTo(.examDetailAdmin(
                                        examId: examination.id,
                                        patientId: patientId
                                    ))
                                } label: {
                                    HomeActivityComponent(
                                        slideId: examination.slideId,
                                        status: examination.statusExamination,
                                        date: presenter.formatDateTime(examination.examinationDate),
                                        patientName: examination.patientName,
                                        patientDOB: presenter.formatDate(examination.patientDob),
                                        picName: examination.dpjpName ?? AppText.Patient.Detail.notDeterminedMessage,
                                        viewType: .adminPatientDetail
                                    )
                                }
                                
                            }
                        }
                    }
                } else if presenter.isLoadingPatient {
                    ProgressView(AppText.Patient.Detail.loadingPatientMessage)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.horizontal, Decimal.d20)
            .navigationTitle(AppText.Patient.Detail.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presenter.navigateBack()
                    }) {
                        HStack {
                            Image(AppText.Icon.back)
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await presenter.getPatientById(patientId: patientId)
                    await presenter.getExaminationsByPatientId(patientId: patientId)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    PatientDetail(patientId: "d0c1a2b3-4f5e-6789-91ab-cdef12345678")
}
