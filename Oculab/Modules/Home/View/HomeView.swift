//
//  HomeView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/10/24.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject private var presenter = SharedPresenter()
    @ObservedObject private var homePresenter = HomePresenter()

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                Spacer().frame(height: Decimal.d24)
                VStack(alignment: .leading, spacing: 24) {
                    StatisticComponent()
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
                                    action: { presenter.filterLatestActivity(typeActivity: activityType) }
                                )
                            }
                            .padding(.horizontal, 1)
                        }

                        VStack(spacing: Decimal.d12) {
                            ForEach(presenter.filteredExamination) { exam in
                                Button {
                                    Router.shared.navigateTo(.examDetail(
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
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Tugas Pemeriksaan")
        }
        .ignoresSafeArea()
        .onAppear {
            homePresenter.getStatisticData()
            presenter.fetchData()
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    HomeView()
}
