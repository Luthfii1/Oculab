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

struct StatisticComponent: View {
    @EnvironmentObject var homePresenter: HomePresenter

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "tray.full.fill")
                    .foregroundStyle(AppColors.purple500)

                Text("Statistik Pemeriksaan")
                    .foregroundStyle(AppColors.slate900)
                    .font(AppTypography.s4_1)
            }

            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .center, spacing: 4) {
                    Text(String(homePresenter.positifCount))
                        .foregroundStyle(AppColors.red500)
                        .font(AppTypography.h1)

                    Text("Positif")
                        .foregroundStyle(AppColors.slate900)
                        .font(AppTypography.s6)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(AppColors.red50)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .center, spacing: 4) {
                    Text(String(homePresenter.negatifCount))
                        .foregroundStyle(AppColors.purple500)
                        .font(AppTypography.h1)

                    Text("Negatif")
                        .foregroundStyle(AppColors.slate900)
                        .font(AppTypography.s6)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(AppColors.purple50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button {
                homePresenter.newInputPatient()
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundStyle(AppColors.slate0)

                    Text("Pemeriksaan Baru")
                        .foregroundStyle(AppColors.slate0)
                        .font(AppTypography.s5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppColors.purple500)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.slate100, lineWidth: 1)
        )
    }
}
