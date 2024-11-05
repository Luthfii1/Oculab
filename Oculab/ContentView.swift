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

                PDFPageView()
                    .tabItem {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Riwayat")
                    }

                PDFPageView()
                    .tabItem {
                        Image(systemName: "person.circle")
                        Text("Profil")
                    }
//                AnalysisResultView()
//                    .tabItem {
//                        Image(systemName: "person.crop.circle.fill")
//                        Text("Analyze")
//                    }
            }
            .tint(AppColors.purple500)
        }
        .environmentObject(Router.shared)
    }
}

#Preview {
    ContentView()
}
