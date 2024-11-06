//
//  HistoryView.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 05/11/24.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject private var presenter = SharedPresenter()
    @State var selectedDate = Date()

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Decimal.d16) {
                    WeeklyCalendarView(selectedDate: $selectedDate)

                    VStack(spacing: Decimal.d12) {
                        ForEach(presenter.filteredExaminationByDate) { exam in
                            Button {
                                Router.shared.navigateTo(.savedResult(
                                    examId: exam.id,
                                    patientId: exam.patientId ?? ""

                                ))
                            } label: {
                                HomeActivityComponent(
                                    slideId: exam.slideId,
                                    status: exam.statusExamination,
                                    date: exam.datePlan,
                                    patientName: exam.patientName,
                                    patientDOB: exam.patientDob
                                )
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
            presenter.fetchData()
        }
        .onChange(of: selectedDate) {
            presenter.filterLatestActivityByDate(date: selectedDate)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    HistoryView()
}
