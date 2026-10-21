//
//  HomeView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/10/24.
//
//
import SwiftUI

struct HomeView: View {
    @StateObject private var presenter: HomeHistoryPresenter
    @ObservedObject private var uploadQueue = VideoUploadQueueService.shared
    @ObservedObject private var networkStatus = DependencyInjection.shared.networkRetryManager
    @EnvironmentObject private var authentication: AuthenticationPresenter
    @State private var loadTask: Task<Void, Never>?
    @State private var refreshTask: Task<Void, Never>?
    @State private var trackedAnalysisIds: [String] = []
    @FocusState private var isSearchFocused: Bool

    private let tabBarScrollInset: CGFloat = 96

    init(presenter: @autoclosure @escaping () -> HomeHistoryPresenter = HomeHistoryPresenter()) {
        _presenter = StateObject(wrappedValue: presenter())
    }

    private var isSearching: Bool {
        isSearchFocused || !presenter.taskSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 20, pinnedViews: [.sectionHeaders]) {
                        if !isSearching {
                            StatisticComponent(isLab: authentication.user.role == .LAB)
                                .environmentObject(presenter)
                            taskSectionHeader
                        }

                        Section {
                            taskListSection
                        } header: {
                            taskSearchBar
                                .padding(.vertical, 8)
                                .background(AppColors.slate0)
                                .id("home-task-search")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, Decimal.d16)
                    .padding(.bottom, tabBarScrollInset)
                    .id("home-task-top")
                }
                .scrollDismissesKeyboard(.interactively)
                .refreshable {
                    refreshTask?.cancel()
                    refreshTask = Task {
                        await presenter.refreshHome(userRole: authentication.user.role)
                    }
                    await refreshTask?.value
                }
                .task(id: isSearching) {
                    await Task.yield()
                    guard !Task.isCancelled else { return }
                    scrollProxy.scrollTo(isSearching ? "home-task-search" : "home-task-top", anchor: .top)
                }
            }
            .navigationTitle(AppTextHomeHistory.navigationTitleHome)
            .navigationBarTitleDisplayMode(isSearching ? .inline : .large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSearching {
                        Button(AppCommon.cancel) {
                            isSearchFocused = false
                            presenter.updateTaskSearchQuery("")
                        }
                    } else {
                        CompactNetworkStatusView()
                    }
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
            Button(AppCommon.cancel, role: .cancel) {}
        } message: {
            Text(AppTextAuthProfile.clinicalActionBlockedMessage)
        }
        .onAppear {
            refreshTrackedAnalysisIds()
            loadTask?.cancel()
            loadTask = Task {
                await presenter.refreshHome(userRole: authentication.user.role)
            }
        }
        .onDisappear {
            isSearchFocused = false
            loadTask?.cancel()
            refreshTask?.cancel()
        }
        .onChange(of: networkStatus.isConnected) { _, isConnected in
            guard isConnected else { return }
            loadTask?.cancel()
            loadTask = Task {
                await presenter.refreshHome(userRole: authentication.user.role)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .examinationAnalysisReady)) { _ in
            refreshTask?.cancel()
            refreshTask = Task {
                await presenter.refreshHome(userRole: authentication.user.role)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .examinationAnalysisProgress)) { _ in
            refreshTrackedAnalysisIds()
            refreshTask?.cancel()
            refreshTask = Task {
                await presenter.fetchData(userRole: authentication.user.role)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Task list

    private var taskSectionHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: AppIcon.docOnDocFill)
                .foregroundStyle(AppColors.purple500)

            Text(AppTextHomeHistory.taskSectionTitle)
                .foregroundStyle(AppColors.slate900)
                .font(AppTypography.s4_1)

            Spacer()

            if presenter.isAllExamsLoading && presenter.hasLoadedExaminations {
                ProgressView().accessibilityLabel(AppTextHomeHistory.refreshingLabel)
            }
            if presenter.hasLoadedExaminations && presenter.hasAnyExaminations {
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
    }

    private var taskSearchBar: some View {
        AppSearchBar(
            searchText: Binding(
                get: { presenter.taskSearchQuery },
                set: { presenter.updateTaskSearchQuery($0) }
            ),
            placeholder: AppTextHomeHistory.searchPlaceholder,
            focus: $isSearchFocused,
            onSearch: {
                presenter.updateTaskSearchQuery(presenter.taskSearchQuery)
            }
        )
    }

    private var taskListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            filterChips

            if uploadQueue.pendingCount > 0 {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: AppIcon.cloudArrowUp)
                        .foregroundStyle(AppColors.orange500)
                    Text(String(format: AppTextExam.uploadQueueBanner, uploadQueue.pendingCount))
                        .font(AppTypography.p3)
                        .foregroundStyle(AppColors.slate600)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.orange50)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if presenter.isShowingCachedData, let cachedAt = presenter.cachedAt {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: AppIcon.wifiSlash)
                        .foregroundStyle(AppColors.slate500)
                    Text(String(format: AppTextHomeHistory.offlineCacheBanner, cachedAt.formattedDayMonthYearTime()))
                        .font(AppTypography.p3)
                        .foregroundStyle(AppColors.slate600)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.slate50)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if !trackedAnalysisIds.isEmpty {
                Button {
                    if let examId = trackedAnalysisIds.first {
                        Router.shared.navigateTo(.analysisResult(examinationId: examId))
                    }
                } label: {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: AppIcon.clockArrowCirclepath)
                            .foregroundStyle(AppColors.purple500)
                        Text(String(format: AppTextHomeHistory.analysisResumeBanner, trackedAnalysisIds.count))
                            .font(AppTypography.p3)
                            .foregroundStyle(AppColors.slate600)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Image(systemName: AppIcon.forward)
                            .foregroundStyle(AppColors.purple500)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.purple50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }

            if !isSearching && showsNewExaminationButton {
                AppButton(
                    title: AppTextHomeHistory.newExaminationButton,
                    leftIcon: AppIcon.docBadgePlus,
                    size: .large,
                    isEnabled: !authentication.isRefreshingEmailVerification
                ) {
                    guard authentication.requireEmailVerificationForClinicalAction() else { return }
                    Router.shared.navigateTo(.inputPatientData())
                }
            }

            if presenter.hasLoadedExaminations && !presenter.loadErrorMessage.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(presenter.loadErrorMessage)
                        .font(AppTypography.p3)
                        .foregroundStyle(AppColors.slate600)
                    Button(AppTextHomeHistory.loadErrorRetry) {
                        loadTask?.cancel()
                        loadTask = Task { await presenter.refreshHome(userRole: authentication.user.role) }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(AppColors.orange50, in: RoundedRectangle(cornerRadius: 10))
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
        if presenter.isAllExamsLoading && !presenter.hasLoadedExaminations {
            VStack(spacing: 12) {
                ProgressView()
                Text(AppTextHomeHistory.loadingState)
                    .font(AppTypography.p3)
                    .foregroundStyle(AppColors.slate400)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)

        } else if !presenter.loadErrorMessage.isEmpty && !presenter.hasLoadedExaminations {
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
                        await presenter.refreshHome(userRole: authentication.user.role)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)

        } else if presenter.filteredExamination.isEmpty {
            emptyTasksView

        } else {
            LazyVStack(spacing: 12) {
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
                            viewType: authentication.user.role == .ADMIN ? .admin : .lab,
                            showsPendingUpload: uploadQueue.hasPendingUpload(for: exam.examinationId)
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
        guard networkStatus.isConnected, !presenter.isShowingCachedData else { return false }
        return authentication.user.role == .ADMIN
            || (authentication.user.role == .LAB && authentication.user.businessModel == .B2C)
    }

    private func refreshTrackedAnalysisIds() {
        trackedAnalysisIds = Array(AnalysisTrackingStore.trackedIds).sorted()
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
