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
    @AppStorage(UserDefaultType.hasSeenOnboarding.rawValue) var hasSeenOnboarding: Bool = false
    @StateObject private var routeFinder = RouteFinder.shared
    @StateObject private var authPresenter = DependencyInjection.shared.createAuthPresenter()

    init() {
        do {
            self.container = try ModelContainer(for: User.self)
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error.localizedDescription)")
        }
        
        DependencyInjection.shared.initializer(modelContext: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            AccountCheckerView()
                .environmentObject(authPresenter)
                .environmentObject(routeFinder)
                .colorScheme(.light)
                .onOpenURL { url in
                    handleDeeplink(url)
                }
        }
        .modelContainer(container)
    }
    
    // MARK: - Deeplink Handling
    private func handleDeeplink(_ url: URL) {
        Logger.info("Received deeplink: \(url.absoluteString)", category: .navigation)
        
        let result = routeFinder.processDeeplink(url)
        
        switch result {
        case .success(let route):
            // If user is authenticated or route doesn't require auth, navigate immediately
            if routeFinder.isUserAuthenticated() || !requiresAuthentication(route) {
                routeFinder.navigateToDeeplink(result)
            } else {
                // Store the route for later navigation after authentication
                routeFinder.setPendingDeeplink(route)
                routeFinder.navigateToDeeplink(.authenticationRequired)
            }
            
        case .authenticationRequired:
            routeFinder.navigateToDeeplink(result)
            
        default:
            routeFinder.navigateToDeeplink(result)
        }
    }
    
    private func requiresAuthentication(_ route: Router.Route) -> Bool {
        switch route {
        case .register, .login:
            return false
        default:
            return true
        }
    }
}
