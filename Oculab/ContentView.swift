//
//  ContentView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 03/10/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        RouterView {
            TabView {
                HomeView()
                    .tabItem {
                        Image(systemName: "rectangle.split.2x2.fill")
                        Text("Pemeriksaan")
                    }

                HistoryView(selectedDate: Date())
                    .tabItem {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Riwayat")
                    }

                InputPatientData()
                    .tabItem {
                        Image(systemName: "person.circle")
                        Text("Profil")
                    }
            }
            .tint(AppColors.purple500)
        }
        .environmentObject(Router.shared)
    }
}

#Preview {
    ContentView()
}
