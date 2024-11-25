//
//  OculabApp.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 03/10/24.
//  Main App

import SwiftData
import SwiftUI

@main
struct OculabApp: App {
    let container: ModelContainer

    init() {
        do {
            self.container = try ModelContainer(for: User.self)
            DependencyInjection.shared.initializer(modelContext: container.mainContext)
        } catch {
            fatalError("Failed to initialize SwiftData")
        }
    }

    var body: some Scene {
        WindowGroup {
//            InputPatientData()
            AccountCheckerView()
                .environmentObject(DependencyInjection.shared.createAuthPresenter())
//            VideoPlayerView()
        }
        .modelContainer(container)
    }
}
