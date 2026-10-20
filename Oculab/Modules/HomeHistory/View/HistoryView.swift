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

    @State private var loadTask: Task<Void, Never>?
    @State private var showFilterSheet = false

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: Decimal.d16) {
                    if presenter.usesAdvancedHistoryFilters {
                        activeFilterSummary
                    } else {
                        WeeklyCalendar(selectedDate: $selectedDate) { newDate in
                            selectedDate = newDate
                        }
                    }

                    historyContent
                }
                .padding(.bottom, 96)
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable {
                await startLoad(.refresh).value
            }
            .padding(.horizontal, Decimal.d20)
            .navigationTitle(AppTextHomeHistory.navigationTitleHistory)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppTextHomeHistory.historyFilterButton) {
                        showFilterSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            HistoryFilterSheet(filters: presenter.historyFilters) { filters in
                startLoad(.apply(filters))
            }
        }
        .onAppear {
            startLoad(.refresh)
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            if !Calendar.current.isDate(oldValue, inSameDayAs: newValue),
               !presenter.usesAdvancedHistoryFilters {
                startLoad(.date(newValue))
            }
        }
        .onDisappear {
            loadTask?.cancel()
        }
        .navigationBarBackButtonHidden(true)
    }

    @ViewBuilder
    private var historyContent: some View {
        if presenter.isAllExamsLoading && !presenter.hasLoadedHistory {
            ProgressView(AppTextHomeHistory.loadingState)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Decimal.d24)
        } else {
            if presenter.isAllExamsLoading {
                ProgressView(AppTextHomeHistory.refreshingLabel)
                    .font(AppTypography.p3)
                    .frame(maxWidth: .infinity)
            }

            if !presenter.loadErrorMessage.isEmpty {
                loadError
            }

            if !presenter.finishedExaminationsByDate.isEmpty {
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
            } else if presenter.hasLoadedHistory && presenter.loadErrorMessage.isEmpty {
                emptyState
            }
        }
    }

    private var activeFilterSummary: some View {
        VStack(alignment: .leading, spacing: Decimal.d8) {
            HStack(alignment: .firstTextBaseline) {
                Text(AppTextHomeHistory.historyFilterTitle)
                    .font(AppTypography.s4_1)
                Spacer()
                Button(AppTextHomeHistory.historyFilterReset) {
                    startLoad(.reset)
                }
                .font(AppTypography.p3)
            }
            Label(
                AppTextHomeHistory.historyDateRange(
                    from: formatDate(presenter.historyFilters.fromDate),
                    to: formatDate(presenter.historyFilters.toDate)
                ),
                systemImage: "calendar"
            )
            Text(AppTextHomeHistory.historyFilterStatus + ": " + (
                presenter.historyFilters.status?.description ?? AppTextHomeHistory.historyFilterAnyStatus
            ))
            Text(AppTextHomeHistory.historyFilterGrading + ": " + (
                presenter.historyFilters.grading?.rawValue ?? AppTextHomeHistory.historyFilterAnyGrading
            ))
        }
        .font(AppTypography.p3)
        .foregroundStyle(AppColors.slate600)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColors.purple50, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .contain)
    }

    private var loadError: some View {
        VStack(spacing: Decimal.d12) {
            Text(presenter.loadErrorMessage)
                .font(AppTypography.p3)
                .foregroundStyle(AppColors.slate600)
                .multilineTextAlignment(.center)
            AppButton(
                title: AppTextHomeHistory.loadErrorRetry,
                colorType: .primary,
                size: .large,
                isEnabled: !presenter.isAllExamsLoading
            ) {
                startLoad(.refresh)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Decimal.d24)
    }

    private var emptyState: some View {
        VStack {
            Image(AppTextHomeHistory.emptyStateImageName)
            Text(presenter.usesAdvancedHistoryFilters
                 ? AppTextHomeHistory.historyFilteredEmpty
                 : AppData.makeSentence([AppTextHomeHistory.noExaminationMessage, formatDate(selectedDate)]))
                .font(AppTypography.p3)
                .foregroundStyle(AppColors.slate500)
                .frame(maxWidth: 280)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Decimal.d24)
    }

    private enum LoadAction {
        case refresh
        case date(Date)
        case apply(HistoryExamFilters)
        case reset
    }

    @discardableResult
    private func startLoad(_ action: LoadAction) -> Task<Void, Never> {
        loadTask?.cancel()
        let task = Task {
            guard !Task.isCancelled else { return }
            switch action {
            case .refresh:
                if presenter.usesAdvancedHistoryFilters {
                    await presenter.fetchFilteredExaminations()
                } else {
                    await presenter.fetchFinishedExaminationsByDate(date: selectedDate)
                }
            case .date(let date):
                await presenter.fetchFinishedExaminationsByDate(date: date)
            case .apply(let filters):
                await presenter.applyHistoryFilters(filters)
            case .reset:
                await presenter.resetHistoryFilters(around: selectedDate)
            }
        }
        loadTask = task
        return task
    }

    private func formatDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}
