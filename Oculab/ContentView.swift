//
//  ContentView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 03/10/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authPresenter: AuthenticationPresenter
    
    var body: some View {
        TabView {
            homeTab
            historyTab
            profileTab
        }
        .tint(AppColors.purple500)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Tab Views
private extension ContentView {
    var homeTab: some View {
        HomeView()
            .environmentObject(DependencyInjection.shared.createAuthPresenter())
            .tabItem {
                Image(systemName: AppIcon.rectangleSplit2x2Fill)
                Text(AppNav.examination)
            }
    }
    
    @ViewBuilder
    var historyTab: some View {
        Group {
            if authPresenter.user.role == .LAB {
                HistoryView(selectedDate: Date())
            } else {
                PatientListView()
            }
        }
        .tabItem {
            Image(systemName: AppIcon.clockArrowCirclepath)
            Text(AppNav.history)
        }
    }
    
    var profileTab: some View {
        ProfileView()
            .environmentObject(DependencyInjection.shared.createAuthPresenter())
            .environmentObject(DependencyInjection.shared.createProfilePresenter())
            .tabItem {
                Image(systemName: AppIcon.personCircle)
                Text(AppNav.profile)
            }
    }
}

#Preview {
    ContentView()
        .environmentObject(DependencyInjection.shared.createAuthPresenter())
}
