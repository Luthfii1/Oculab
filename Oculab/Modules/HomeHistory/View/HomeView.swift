//
//  HomeView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/10/24.
//
//
import SwiftUI

struct HomeView: View {
    @StateObject private var presenter = HomeHistoryPresenter()
    @EnvironmentObject private var authentication: AuthenticationPresenter
    @State private var loadTask: Task<Void, Never>?
    @State private var refreshTask: Task<Void, Never>?

    private let tabBarScrollInset: CGFloat = 96

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                Spacer().frame(height: Decimal.d16)

                VStack(alignment: .leading, spacing: 20) {
                    StatisticComponent(isLab: authentication.user.role == .LAB)
                        .environmentObject(presenter)

                    taskListSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, tabBarScrollInset)
            }
            .refreshable {
                refreshTask?.cancel()
                refreshTask = Task {
                    await presenter.getStatisticData()
                    await presenter.fetchData(userRole: authentication.user.role)
                }
                await refreshTask?.value
            }
            .navigationTitle(AppTextHomeHistory.navigationTitleHome)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CompactNetworkStatusView()
                }
            }
        }
        .background(AppColors.slate0)
        .alert(
            AppTextAuthProfile.clinicalActionBlockedTitle,
            isPresented: $authentication.showEmailVerificationAlert
        ) {
            Button(AppTextAuthProfile.clinicalActionBlockedButton) {
                Router.shared.navigateTo(.profile)
            }
            Button(AppState.cancel, role: .cancel) {}
        } message: {
            Text(AppTextAuthProfile.clinicalActionBlockedMessage)
        }
        .onAppear {
            loadTask?.cancel()
            loadTask = Task {
                await presenter.getStatisticData()
                await presenter.fetchData(userRole: authentication.user.role)
            }
        }
        .onDisappear {
            loadTask?.cancel()
            refreshTask?.cancel()
        }
        .onReceive(NotificationCenter.default.publisher(for: .examinationAnalysisReady)) { _ in
            refreshTask?.cancel()
            refreshTask = Task {
                await presenter.getStatisticData()
                await presenter.fetchData(userRole: authentication.user.role)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .examinationAnalysisProgress)) { _ in
            refreshTask?.cancel()
            refreshTask = Task {
                await presenter.fetchData(userRole: authentication.user.role)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Task list

    private var taskListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: AppIcon.docOnDocFill)
                    .foregroundStyle(AppColors.purple500)

                Text(AppTextHomeHistory.taskSectionTitle)
                    .foregroundStyle(AppColors.slate900)
                    .font(AppTypography.s4_1)

                Spacer()

                if !presenter.isAllExamsLoading && presenter.hasAnyExaminations {
                    Text(
                        String(
                            format: AppTextHomeHistory.taskCountFormat,
                            presenter.filteredExamination.count
                        )
                    )
                    .font(AppTypography.p5)
                    .foregroundStyle(AppColors.slate400)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppColors.purple50)
                    .clipShape(Capsule())
                }
            }

            filterChips

            AppSearchBar(
                searchText: Binding(
                    get: { presenter.taskSearchQuery },
                    set: { presenter.updateTaskSearchQuery($0) }
                ),
                placeholder: AppTextHomeHistory.searchPlaceholder,
                onSearch: {
                    presenter.updateTaskSearchQuery(presenter.taskSearchQuery)
                }
            )

            if showsNewExaminationButton {
                AppButton(
                    title: AppTextHomeHistory.newExaminationButton,
                    leftIcon: AppIcon.docBadgePlus,
                    size: .large
                ) {
                    guard authentication.requireEmailVerificationForClinicalAction() else { return }
                    Router.shared.navigateTo(.inputPatientData())
                }
            }

            taskListContent
        }
    }

    private var filterChips: some View {
        HStack(alignment: .center, spacing: 8) {
            let activityTypes = authentication.user.role == .ADMIN
                ? [LatestActivityType.semua, .butuhVerifikasi]
                : [LatestActivityType.belumDimulai, .belumDisimpulkan]

            ForEach(activityTypes, id: \.self) { activityType in
                ButtonActivity(
                    labelButton: activityType.displayValue,
                    count: presenter.examinationCount(for: activityType),
                    isSelected: presenter.selectedLatestActivity == activityType,
                    action: {
                        Task {
                            await presenter.filterLatestActivity(typeActivity: activityType)
                        }
                    }
                )
            }
        }
    }

    @ViewBuilder
    private var taskListContent: some View {
            if presenter.isAllExamsLoading {
            VStack(spacing: 12) {
                ProgressView()
                Text(AppTextHomeHistory.loadingState)
                    .font(AppTypography.p3)
                    .foregroundStyle(AppColors.slate400)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)

        } else if !presenter.loadErrorMessage.isEmpty {
            VStack(spacing: 12) {
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
                    loadTask?.cancel()
                    loadTask = Task {
                        await presenter.getStatisticData()
                        await presenter.fetchData(userRole: authentication.user.role)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)

        } else if presenter.filteredExamination.isEmpty {
            emptyTasksView

        } else {
            VStack(spacing: 12) {
                ForEach(presenter.filteredExamination) { exam in
                    Button {
                        openExamination(exam)
                    } label: {
                        HomeActivityComponent(
                            slideId: exam.slideId,
                            status: exam.statusExamination,
                            date: exam.datePlan,
                            patientName: exam.patientName,
                            patientDOB: exam.patientDob.toFormattedDate(),
                            picName: exam.picName,
                            viewType: authentication.user.role == .ADMIN ? .admin : .lab
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyTasksView: some View {
        VStack(spacing: 12) {
            Image(AppTextHomeHistory.emptyStateImageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 160)

            Text(emptyStateMessage)
                .font(AppTypography.p3)
                .foregroundStyle(AppColors.slate400)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var emptyStateMessage: String {
        if !presenter.taskSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return AppTextHomeHistory.noTasksInSearchMessage
        }
        if presenter.hasAnyExaminations {
            return AppTextHomeHistory.noTasksInFilterMessage
        }
        return AppTextHomeHistory.noTaskMessage
    }

    private var showsNewExaminationButton: Bool {
        authentication.user.role == .ADMIN
            || (authentication.user.role == .LAB && authentication.user.businessModel == .B2C)
    }

    private func openExamination(_ exam: ExaminationCardData) {
        if authentication.user.role == .ADMIN {
            Router.shared.navigateTo(.examDetailAdmin(
                examId: exam.id,
                patientId: exam.patientId
            ))
        } else if exam.statusExamination == .NOTSTARTED {
            Router.shared.navigateTo(.examDetail(
                examId: exam.id,
                patientId: exam.patientId
            ))
        } else {
            Router.shared.navigateTo(.analysisResult(examinationId: exam.id))
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(DependencyInjection.shared.createAuthPresenter())
}
