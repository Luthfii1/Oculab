//
//  HomeView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/10/24.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject private var homePresenter = HomePresenter()

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                Spacer().frame(height: Decimal.d24)
                VStack(alignment: .leading, spacing: 24) {
                    StatisticComponent()
                        .environmentObject(homePresenter)

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
                                    isSelected: homePresenter.selectedLatestActivity == activityType,
                                    action: { homePresenter.filterLatestActivity(typeActivity: activityType) }
                                )
                            }
                            .padding(.horizontal, 1)
                        }

                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(homePresenter.filteredExamination) { exam in
                                HomeActivityComponent(
                                    fileName: exam.imagePreview,
                                    slideId: exam.slideId,
                                    status: exam.statusExamination,
                                    date: exam.date,
                                    time: exam.time
                                )
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
            homePresenter.fetchData()
//            homePresenter.inputNewPatient()
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    HomeView()
}
