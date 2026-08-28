//
//  HistoryView.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 05/11/24.
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var presenter = HomeHistoryPresenter()
    @State var selectedDate: Date

    @State private var currentlyLoadedDate: Date?
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Decimal.d16) {
                    WeeklyCalendar(selectedDate: $selectedDate) { newDate in
                        selectedDate = newDate
                    }

                    if presenter.isAllExamsLoading {
                        Spacer().frame(height: Decimal.d24)
                        VStack(alignment: .center) {
                            ProgressView(AppTextHomeHistory.loadingState)
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        .frame(maxWidth: .infinity)

                    } else if !presenter.loadErrorMessage.isEmpty {
                        VStack(spacing: Decimal.d12) {
                            Text(presenter.loadErrorMessage)
                                .font(AppTypography.p3)
                                .foregroundStyle(AppColors.slate600)
                                .multilineTextAlignment(.center)
                            AppButton(
                                title: AppTextHomeHistory.loadErrorRetry,
                                colorType: .primary,
                                size: .large,
                                isEnabled: true
                            ) {
                                loadDataForDate(selectedDate)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Decimal.d24)

                    } else if shouldShowEmptyState() {
                        VStack(alignment: .center) {
                            Image(AppTextHomeHistory.emptyStateImageName)
                            Text(AppData.makeSentence([AppTextHomeHistory.noExaminationMessage, formatDate(selectedDate)]))
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
            .navigationTitle(AppTextHomeHistory.navigationTitleHistory)
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
        .onDisappear {
            loadTask?.cancel()
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

        loadTask?.cancel()
        loadTask = Task {
            await presenter.fetchFinishedExaminationsByDate(date: date)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current // Use current system locale for localization
        dateFormatter.dateFormat = "dd MMMM yyyy"
        return dateFormatter.string(from: date)
    }
}

//#Preview {
//    HistoryView(selectedDate: Date())
//}
