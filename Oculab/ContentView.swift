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
                        Text("Ringkasan")
                    }

                PDFPageView()
                    .tabItem {
                        Image(systemName: "folder.fill.badge.person.crop")
                        Text("PDF")
                    }

                AnalysisResultView()
                    .tabItem {
                        Image(systemName: "person.crop.circle.fill")
                        Text("Analyze")
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
