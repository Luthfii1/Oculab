//
//  ContentView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 03/10/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dependencyInjection: DependencyInjection
    @EnvironmentObject private var authPresenter: AuthenticationPresenter
    
    var body: some View {
        TabView {
            HomeView()
                .environmentObject(DependencyInjection.shared.createAuthPresenter())
                .tabItem {
                    Image(systemName: AppIcon.rectangleSplit2x2Fill)
                    Text(AppNav.examination)
                }
            if authPresenter.user.role == .LAB {
                HistoryView(selectedDate: Date())
                    .tabItem {
                        Image(systemName: AppIcon.clockArrowCirclepath)
                        Text(AppNav.history)
                    }
            } else {
                PatientListView()
                    .tabItem {
                        Image(systemName: AppIcon.clockArrowCirclepath)
                        Text(AppNav.history)
                    }
            }
            
            ProfileView()
                .environmentObject(DependencyInjection.shared.createAuthPresenter())
                .environmentObject(DependencyInjection.shared.createProfilePresenter())
                .tabItem {
                    Image(systemName: AppIcon.personCircle)
                    Text(AppNav.profile)
                }
        }
        .tint(AppColors.purple500)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ContentView()
        .environmentObject(DependencyInjection.shared)
}
