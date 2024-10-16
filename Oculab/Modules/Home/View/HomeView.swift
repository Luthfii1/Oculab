//
//  HomeView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/10/24.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var homePresenter = HomePresenter()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    StatisticComponent()
                        .environmentObject(homePresenter)

                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "clock")
                                .foregroundStyle(AppColors.purple500)

                            Text("Aktivitas Terbaru")
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

                        // TODO: Create component for Sample Preview
                    }
                }
            }
            .padding(.bottom, 24)
            .padding(.horizontal, 20)
            .navigationTitle("Ringkasan")
            .foregroundStyle(AppColors.slate900)
        }
        .background(AppColors.slate0)
        .ignoresSafeArea()
        .onAppear {
            homePresenter.getStatisticData()
        }
    }
}

#Preview {
    HomeView()
}
