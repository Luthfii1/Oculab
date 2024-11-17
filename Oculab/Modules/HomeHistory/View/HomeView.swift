//
//  HomeView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/10/24.
//
//
import SwiftUI

struct HomeView: View {
    @ObservedObject private var presenter = HomeHistoryPresenter()
    @EnvironmentObject private var authentication: AuthenticationPresenter

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                Spacer().frame(height: Decimal.d24)

                VStack(alignment: .leading, spacing: 24) {
                    StatisticComponent(isLab: authentication.user.role == .LAB)
                        .environmentObject(presenter)

                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "doc.on.doc.fill")
                                .foregroundStyle(AppColors.purple500)

                            Text("Tugas Pemeriksaan")
                                .foregroundStyle(AppColors.slate900)
                                .font(AppTypography.s4_1)
                        }

                        HStack(alignment: .center, spacing: 8) {
                            ForEach(LatestActivityType.allCases, id: \.self) { activityType in
                                ButtonActivity(
                                    labelButton: activityType.rawValue,
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
                            AppButton(title: "Pemeriksaan Baru", leftIcon: "doc.badge.plus") {
                                Router.shared.navigateTo(.inputPatientData)
                            }
                        }

                        if presenter.isAllExamsLoading {
                            Spacer().frame(height: Decimal.d24)
                            VStack(alignment: .center) {
                                ProgressView("Memuat data pemeriksaan anda")
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            .frame(maxWidth: .infinity)

                        } else if presenter.filteredExamination.isEmpty {
                            VStack(alignment: .center) {
                                Image("Empty")
                                Text("Anda belum ditugaskan untuk melakukan pemeriksaan").font(AppTypography.p3)
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
                                                Router.shared.navigateTo(.analysisResult(examinationId: exam.id))
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
                                            isLab: authentication.user.role == .LAB
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
            .navigationTitle("Tugas Pemeriksaan")
        }
        .ignoresSafeArea()
        .onAppear {
            Task {
                await presenter.getStatisticData()
                await presenter.fetchData()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    HomeView()
        .environmentObject(DependencyInjection.shared.createAuthPresenter())
}
