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
            AppTextBox(
                title: "Description",
                placeholder: "Enter your description here...",
                isRequired: true,
                description: "This is a required field",
                isDisabled: false,
                text: .constant("")
            )

            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
