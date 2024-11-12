//
//  HistoryView.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 05/11/24.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject private var presenter = HomeHistoryPresenter()
    @State var selectedDate: Date

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Decimal.d16) {
                    WeeklyCalendarView(selectedDate: $selectedDate)

                    if presenter.isAllExamsLoading {
                        Spacer().frame(height: Decimal.d24)
                        VStack(alignment: .center) {
                            ProgressView("Memuat data pemeriksaan anda")
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        .frame(maxWidth: .infinity)

                    } else if presenter.filteredExaminationByDate.isEmpty {
                        VStack(alignment: .center) {
                            Image("Empty")
                            Text("Tidak ada pemeriksaan diselesaikan pada \(selectedDate)").font(AppTypography.p3)
                                .foregroundStyle(AppColors.slate300)
                                .frame(maxWidth: 254)
                                .multilineTextAlignment(.center)
                        }.frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: Decimal.d12) {
                            ForEach(presenter.filteredExaminationByDate) { exam in
                                Button {
                                    Router.shared.navigateTo(.savedResult(
                                        examId: exam.id,
                                        patientId: exam.patientId
                                    ))
                                } label: {
                                    HomeActivityComponent(
                                        slideId: exam.slideId,
                                        status: exam.statusExamination,
                                        date: exam.datePlan,
                                        patientName: exam.patientName,
                                        patientDOB: exam.patientDob,
                                        picName: exam.picName,
                                        isLab: true
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Decimal.d20)
            .navigationTitle("Riwayat")
        }
        .ignoresSafeArea()
        .onAppear {
            Task {
                await presenter.fetchData()
            }
        }
        .onChange(of: selectedDate) {
            presenter.filterLatestActivityByDate(date: selectedDate)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    HistoryView(selectedDate: Date())
}
