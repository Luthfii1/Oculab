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

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                Spacer().frame(height: Decimal.d24)

                VStack(alignment: .leading, spacing: 24) {
                    StatisticComponent(isLab: authentication.user.role == .LAB)
                        .environmentObject(presenter)

                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: AppIcon.docOnDocFill)
                                .foregroundStyle(AppColors.purple500)

                            Text(AppTextHomeHistory.taskSectionTitle)
                                .foregroundStyle(AppColors.slate900)
                                .font(AppTypography.s4_1)
                        }

                        HStack(alignment: .center, spacing: 8) {
                            let activityTypes = authentication.user.role == .ADMIN
                                ? [LatestActivityType.semua, .butuhVerifikasi]
                                : [LatestActivityType.belumDimulai, .belumDisimpulkan]
                            
                            ForEach(activityTypes, id: \.self) { activityType in
                                ButtonActivity(
                                    labelButton: activityType.displayValue,
                                    isSelected: presenter.selectedLatestActivity == activityType,
                                    action: {
                                        Task {
                                            await presenter.filterLatestActivity(typeActivity: activityType)
                                        }
                                    }
                                )
                            }
                            .padding(.horizontal, 1)
                        }

                        if authentication.user.role == .ADMIN {
                            AppButton(title: AppTextHomeHistory.newExaminationButton, leftIcon: AppIcon.docBadgePlus) {
                                Router.shared.navigateTo(.inputPatientData())
                            }
                        }  else if authentication.user.role == .LAB && authentication.user.businessModel == .B2C {
                            AppButton(title: AppTextHomeHistory.newExaminationButton, leftIcon: AppIcon.docBadgePlus) {
                                Router.shared.navigateTo(.inputPatientData())
                            }
                        }

                        if presenter.isAllExamsLoading {
                            Spacer().frame(height: Decimal.d24)
                            VStack(alignment: .center) {
                                ProgressView(AppTextHomeHistory.loadingState)
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            .frame(maxWidth: .infinity)

                        } else if presenter.filteredExamination.isEmpty {
                            VStack(alignment: .center) {
                                Image(AppTextHomeHistory.emptyStateImageName)
                                Text(AppTextHomeHistory.noTaskMessage).font(AppTypography.p3)
                                    .foregroundStyle(AppColors.slate300)
                                    .frame(maxWidth: 254)
                                    .multilineTextAlignment(.center)
                            }.frame(maxWidth: .infinity)
                            
                        } else {
                            VStack(spacing: Decimal.d12) {
                                ForEach(presenter.filteredExamination) { exam in
                                    Button {
                                        if authentication.user.role == .ADMIN {
                                            Router.shared.navigateTo(.examDetailAdmin(
                                                examId: exam.id,
                                                patientId: exam.patientId
                                            ))
                                        } else {
                                            if exam.statusExamination == .NOTSTARTED {
                                                Router.shared.navigateTo(.examDetail(
                                                    examId: exam.id,
                                                    patientId: exam.patientId
                                                ))
                                            } else {
                                                Router.shared.navigateTo(.analysisResult(
                                                    examinationId: exam.id
                                                ))
                                            }
                                        }
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
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
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
        .ignoresSafeArea()
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
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    HomeView()
        .environmentObject(DependencyInjection.shared.createAuthPresenter())
}
