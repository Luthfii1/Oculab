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
                    
                    AppCard(icon: "person.fill", title: "Data Pasien", spacing: Decimal.d16, isEnablingEdit: true) {
                        ExtendedCard(data: [
                            ("Nama", presenter.patient.name),
                            ("NIK", presenter.patient.NIK),
                            ("Tanggal Lahir", presenter.formatDate(presenter.patient.DoB)),
                            ("Jenis Kelamin", presenter.patient.sex.rawValue),
                            ("Nomor BPJS", presenter.patient.BPJS ?? ""),
                        ], titleSize: AppTypography.s5)
                    } action: {
                        presenter.navigateTo(.patientForm(patientId: patientId))
                    }
                    
                    AppCard(
                        icon: "text.badge.checkmark",
                        title: "Hasil Pemeriksaan",
                        spacing: Decimal.d16,
                        isBorderDisabled: true
                    ) {
                        AppButton(title: "Pemeriksaan Baru", leftIcon: "doc.badge.plus") {
                            presenter.navigateTo(.inputPatientData(patientId: patientId))
                        }
                        
                        if presenter.isLoadingExaminations {
                            ProgressView("Loading examinations...")
                                .frame(maxWidth: .infinity, minHeight: 60)
                        } else if presenter.examinationList.isEmpty {
                            Text("Belum ada pemeriksaan")
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
                                        picName: examination.dpjpName ?? "Belum ditentukan",
                                        viewType: .adminPatientDetail
                                    )
                                }
                                
                            }
                        }
                    }
                } else if presenter.isLoadingPatient {
                    ProgressView("Loading patient data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.horizontal, Decimal.d20)
            .navigationTitle("Riwayat Pemeriksaan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presenter.navigateBack()
                    }) {
                        HStack {
                            Image("back")
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
