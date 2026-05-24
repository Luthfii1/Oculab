//
//  AccountCheckerView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/11/24.
//

import SwiftUI

struct AccountCheckerView: View {
    @AppStorage(UserDefaultType.isUserLoggedIn.rawValue) var isUserLoggedIn: Bool = false
    @EnvironmentObject var authPresenter: AuthenticationPresenter
    @EnvironmentObject var routeFinder: RouteFinder
    @StateObject private var appStateManager = AppStateManager()

    var body: some View {
        RouterView {
            currentView
        }
        .onAppear {
            // Inject appStateManager into authPresenter
            authPresenter.appStateManager = appStateManager
            initializeApp()
        }
        .environmentObject(Router.shared)
        .environmentObject(appStateManager)
        .onChange(of: authPresenter.isPinAuthorized) { _, newValue in
            if newValue {
                // Only set authenticated if we're not already in authenticated state
                if appStateManager.initializationState != .authenticated {
                    appStateManager.setAuthenticated()
                }
                
                // Process any pending deeplink after successful authentication
                Task {
                    await routeFinder.processPendingDeeplink()
                }
            }
        }
        .onChange(of: isUserLoggedIn) { _, newValue in
            if !newValue {
                // User logged out - reset all state
                authPresenter.isPinAuthorized = false
                authPresenter.resetAuthenticationState()
                appStateManager.setUnauthenticated()
            }
        }
    }
}

// MARK: - View Builder
private extension AccountCheckerView {
    @ViewBuilder
    var currentView: some View {
        switch appStateManager.initializationState {
        case .splash, .loading:
            SplashScreenView()
            
        case .authenticated:
            ContentView()
                .environmentObject(authPresenter)
            
        case .requiresPinCreation:
            UserAccessPinView(state: .create)
                .environmentObject(authPresenter)
        
        case .createFaceId:
            ActivateFaceIdView()
                .environmentObject(authPresenter)
            
        case .requiresPinAuthentication:
            UserAccessPinView(state: .authenticate)
                .environmentObject(authPresenter)
            
        case .unauthenticated:
            LoginView()
                .environmentObject(authPresenter)
            
        case .error(let message):
            ErrorView(message: message) {
                Task {
                    await initializeUserState()
                }
            }
        }
    }
}
// MARK: - Initialization Logic
private extension AccountCheckerView {
    func initializeApp() {
        appStateManager.startAppInitialization()
        
        // Check if user is logged in but needs PIN authentication
        if authPresenter.isUserLoggedIn() {
            // For logged-in users, we need to fetch account data to determine PIN status
            // This is essential because PIN requirement is determined server-side
            Task {
                await initializeUserStateWithSplash()
            }
        } else {
            // User not logged in - skip authentication and show login after splash
            Task {
                await initializeUserStateWithSplash()
            }
        }
    }
    
    @MainActor
    func initializeUserStateWithSplash() async {
        // Run splash screen and authentication concurrently
        async let splashDelay: () = Task.sleep(nanoseconds: UInt64(AppConstants.splashScreenDuration * 1_000_000_000))
        async let authenticationTask: () = performAuthentication()
        
        // Wait for both to complete
        do {
            let _ = try await (splashDelay, authenticationTask)
            
            // Don't change state if PIN was already authorized during the flow
            if authPresenter.isPinAuthorized {
                return
            }
            
            // Don't change state if we're already in a PIN authentication state
            if appStateManager.initializationState == .requiresPinAuthentication || 
               appStateManager.initializationState == .requiresPinCreation {
                return
            }
            
            // After both complete, check if we need to show login
            if !authPresenter.isUserLoggedIn() {
                appStateManager.setUnauthenticated()
                authPresenter.isPinAuthorized = false
            }
        } catch {
            appStateManager.setUnauthenticated()
        }
    }
    
    @MainActor
    func performAuthentication() async {
        guard authPresenter.isUserLoggedIn() else {
            // Don't set state here - let splash finish first
            return
        }
        
        await authPresenter.getAccountById()
    }
    
    @MainActor
    func initializeUserState() async {
        // Fallback method for error recovery
        guard authPresenter.isUserLoggedIn() else {
            appStateManager.setUnauthenticated()
            authPresenter.isPinAuthorized = false
            return
        }
        
        await authPresenter.getAccountById()
    }
}

//#Preview {
//    AccountCheckerView()
//        .environmentObject(DependencyInjection.shared.createAuthPresenter())
//}
