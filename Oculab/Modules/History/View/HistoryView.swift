//
//  HistoryView.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 05/11/24.
//

import SwiftUI

struct HistoryView: View {
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {}
                .navigationTitle("Riwayat")
        }
        .ignoresSafeArea()
        .onAppear {}
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    HistoryView()
}
