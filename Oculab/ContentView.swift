//
//  ContentView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 03/10/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .background(.red)
    }
}

#Preview {
    ContentView()
}
