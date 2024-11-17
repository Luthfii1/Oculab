//
//  ContentView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 03/10/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dependencyInjection: DependencyInjection

    var body: some View {
        TabView {
            HomeView()
                .environmentObject(DependencyInjection.shared.createAuthPresenter())
                .tabItem {
                    Image(systemName: "rectangle.split.2x2.fill")
                    Text("Pemeriksaan")
                }

            HistoryView(selectedDate: Date())
                .tabItem {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("Riwayat")
                }

            ProfileView()
                .environmentObject(DependencyInjection.shared.createAuthPresenter())
                .environmentObject(DependencyInjection.shared.createProfilePresenter())
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profil")
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
