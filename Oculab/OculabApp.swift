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
    @UIApplicationDelegateAdaptor(AppNotificationDelegate.self) private var appNotificationDelegate

    let container: ModelContainer
    @AppStorage(UserDefaultType.hasSeenOnboarding.rawValue) var hasSeenOnboarding: Bool = false
    @StateObject private var routeFinder = RouteFinder.shared
    @StateObject private var authPresenter = DependencyInjection.shared.createAuthPresenter()

    init() {
        KeychainHelper.bootstrap()

        do {
            self.container = try Self.makeModelContainer()
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

    /// Beta: wipe local SwiftData when schema version changes instead of migrating.
    private enum SwiftDataBootstrap {
        /// Bump when `@Model` types change in a breaking way.
        static let schemaVersion = 2
    }

    private static func makeModelContainer() throws -> ModelContainer {
        let schema = Schema([User.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let versionKey = UserDefaultType.swiftDataSchemaVersion.rawValue
        let storedVersion = UserDefaults.standard.integer(forKey: versionKey)

        if storedVersion != SwiftDataBootstrap.schemaVersion {
            Logger.info(
                "SwiftData schema changed (\(storedVersion) → \(SwiftDataBootstrap.schemaVersion)); wiping local cache",
                category: .authentication
            )
            try deleteStoreFiles(at: configuration.url)
            UserDefaults.standard.set(SwiftDataBootstrap.schemaVersion, forKey: versionKey)
        }

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private static func deleteStoreFiles(at storeURL: URL) throws {
        let fileManager = FileManager.default
        let relatedURLs = [
            storeURL,
            storeURL.appendingPathExtension("wal"),
            storeURL.appendingPathExtension("shm"),
        ]

        for url in relatedURLs where fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
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
