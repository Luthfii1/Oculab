//
//  PatientDetailView.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 08/11/24.
//

import SwiftUI

struct PatientDetailView: View {
    let patientId: String
    @StateObject private var presenter = PatientPresenter()
    
    var body: some View {
        NavigationView {
            ScrollView {
                if !presenter.isLoadingPatient && !presenter.patient.name.isEmpty {
                    Spacer().frame(height: Decimal.d24)
                    
                    AppCard(icon: AppText.Icon.personFill, title: AppTextPatientDetail.patientDataTitle, spacing: Decimal.d16, isEnablingEdit: true) {
                        ExtendedCard(data: [
                            (AppTextPatientDetail.patientNameKey, presenter.patient.name),
                            (AppTextPatientDetail.patientNikKey, presenter.patient.NIK),
                            (AppTextPatientDetail.patientDobKey, presenter.formatDate(presenter.patient.DoB)),
                            (AppTextPatientDetail.patientSexKey, presenter.patient.sex.rawValue),
                            (AppTextPatientDetail.patientBpjsKey, presenter.patient.BPJS ?? AppText.Common.emptyString),
                        ], titleSize: AppTypography.s5)
                    } action: {
                        presenter.navigateTo(.patientForm(patientId: patientId))
                    }
                    
                    AppCard(
                        icon: AppText.Icon.textBadgeCheckmark,
                        title: AppTextPatientDetail.examinationResultTitle,
                        spacing: Decimal.d16,
                        isBorderDisabled: true
                    ) {
                        AppButton(title: AppTextPatientDetail.newExaminationButton, leftIcon: AppText.Icon.docBadgePlusIcon) {
                            presenter.navigateTo(.inputPatientData(patientId: patientId))
                        }
                        
                        if presenter.isLoadingExaminations {
                            ProgressView(AppTextPatientDetail.loadingExaminationsMessage)
                                .frame(maxWidth: .infinity, minHeight: 60)
                        } else if presenter.examinationList.isEmpty {
                            Text(AppTextPatientDetail.noExaminationsMessage)
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
                                        picName: examination.dpjpName ?? AppTextPatientDetail.notDeterminedMessage,
                                        viewType: .adminPatientDetail
                                    )
                                }
                                
                            }
                        }
                    }
                } else if presenter.isLoadingPatient {
                    ProgressView(AppTextPatientDetail.loadingPatientMessage)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.horizontal, Decimal.d20)
            .navigationTitle(AppTextPatientDetail.navigationTitle)
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
    PatientDetailView(patientId: "d0c1a2b3-4f5e-6789-91ab-cdef12345678")
}
