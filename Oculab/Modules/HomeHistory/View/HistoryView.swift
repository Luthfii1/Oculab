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
    
    @State private var currentlyLoadedDate: Date?

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Decimal.d16) {
                    WeeklyCalendarView(selectedDate: $selectedDate)

                    if presenter.isAllExamsLoading {
                        Spacer().frame(height: Decimal.d24)
                        VStack(alignment: .center) {
                            ProgressView(AppText.HomeHistory.loadingMessage)
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        .frame(maxWidth: .infinity)

                    } else if shouldShowEmptyState() {
                        VStack(alignment: .center) {
                            Image(AppText.HomeHistory.emptyStateImageName)
                            Text("\(AppText.HomeHistory.noExaminationMessage) \(formatDate(selectedDate))")
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
                                        slideId: exam.slideId,
                                        result: exam.finalGradingResult.rawValue,
                                        patientName: exam.patientName,
                                        patientDOB: exam.patientDob.toFormattedDate(),
                                        dpjpName: exam.dpjpName ?? AppValue.empty
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Decimal.d20)
            .navigationTitle(AppText.HomeHistory.navigationTitleHistory)
        }
        .ignoresSafeArea()
        .onAppear {
            loadDataForDate(selectedDate)
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            if !Calendar.current.isDate(oldValue, inSameDayAs: newValue) {
                loadDataForDate(newValue)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func shouldShowEmptyState() -> Bool {
        return presenter.finishedExaminationsByDate.isEmpty &&
               !presenter.isAllExamsLoading &&
               currentlyLoadedDate != nil &&
               Calendar.current.isDate(currentlyLoadedDate!, inSameDayAs: selectedDate)
    }
    
    private func loadDataForDate(_ date: Date) {
        currentlyLoadedDate = date
        
        Task {
            await presenter.fetchFinishedExaminationsByDate(date: date)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "id_ID") // Bahasa Indonesia
        dateFormatter.dateFormat = "dd MMMM yyyy"
        return dateFormatter.string(from: date)
    }
}

#Preview {
    HistoryView(selectedDate: Date())
}
