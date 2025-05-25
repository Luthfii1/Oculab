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

                    } else if presenter.finishedExaminationsByDate.isEmpty {
                        VStack(alignment: .center) {
                            Image("Empty")
                            Text("Tidak ada pemeriksaan diselesaikan pada \(formatDate(selectedDate))")
                                .font(AppTypography.p3)
                                .foregroundStyle(AppColors.slate300)
                                .frame(maxWidth: 254)
                                .multilineTextAlignment(.center)
                        }.frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: Decimal.d12) {
                            ForEach(presenter.finishedExaminationsByDate) { exam in
                                Button {
                                    Router.shared.navigateTo(.savedResult(
                                        examId: exam.id,
                                        patientId: exam.patientId
                                    ))
                                } label: {
                                    FinishedExaminationCard(
                                        slideId: exam.slideId.uppercased(),
                                        result: exam.finalGradingResult,
                                        patientName: exam.patientName.capitalized,
                                        patientDOB: exam.patientDob,
                                        dpjpName: exam.dpjpName
                                    )
                                }
                            }
//                            ForEach(presenter.finishedExaminationsByDate) { exam in
//                                Button {
//                                    Router.shared.navigateTo(.savedResult(
//                                        examId: exam.id,
//                                        patientId: exam.patientId
//                                    ))
//                                } label: {
//                                    FinishedExaminationCard(
//                                        slideId: exam.slideId.uppercased(),
//                                        result: exam.finalGradingResult,
//                                        patientName: exam.patientName.capitalized,
//                                        patientDOB: exam.patientDob,
//                                        dpjpName: exam.dpjpName
//                                    )
//                                    
//                                   
//                                }
//                            }
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
                await presenter.fetchFinishedExaminationsByDate(date: selectedDate)
//                presenter
//                presenter.finishedExaminationsByDate(date: selectedDate)
            }
        }
        .onChange(of: selectedDate) {
            Task {
                await presenter.fetchFinishedExaminationsByDate(date: selectedDate)

//            presenter.filterLatestActivityByDate(date: selectedDate)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "id_ID") // Bahasa Indonesia
        dateFormatter.dateFormat = "dd MMMM yyyy"
        return dateFormatter.string(from: date)
    }
    
    private func formatGradingResult(_ result: String) -> String {
        // Convert "Positive 1+" to "Positif 1+" and "Negative" to "Negatif"
        if result.lowercased().contains("positive") {
            return result.replacingOccurrences(of: "Positive", with: "Positif")
        } else if result.lowercased().contains("negative") {
            return "Negatif"
        }
        return result
    }
}

#Preview {
    HistoryView(selectedDate: Date())
}
