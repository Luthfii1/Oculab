//
//  AppStateManager.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 12/08/25.
//

import Foundation
import SwiftUI

// MARK: - App State Types
enum AppInitializationState: Equatable {
    case splash
    case loading
    case authenticated
    case requiresPinCreation
    case createFaceId
    case requiresPinAuthentication
    case unauthenticated
    case error(String)
}

enum AuthenticationFlow {
    case checking
    case loggedOut
    case loggedInNeedsPin(hasExistingPin: Bool)
    case fullyAuthenticated
}

// MARK: - App State Manager
@MainActor
class AppStateManager: ObservableObject {
    @Published var initializationState: AppInitializationState = .splash
    @Published var authenticationFlow: AuthenticationFlow = .checking
    @Published var isOffline: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    
    private let splashDuration: TimeInterval = AppConstants.splashScreenDuration
    
    func startAppInitialization() {
        Task {
            // Show splash screen
            try await Task.sleep(nanoseconds: UInt64(splashDuration * 1_000_000_000))
            transitionFromSplash()
        }
    }
    
    func transitionFromSplash() {
        // Don't transition to loading if we're already in a PIN state or authenticated
        switch initializationState {
        case .requiresPinCreation, .requiresPinAuthentication, .authenticated:
            return
        default:
            withAnimation(.easeInOut(duration: AppConstants.animationDuration)) {
                initializationState = .loading
            }
        }
    }
    
    func setAuthenticated() {
        withAnimation {
            initializationState = .authenticated
            authenticationFlow = .fullyAuthenticated
        }
    }
    
    func setRequiresPin(hasExistingPin: Bool) {
        withAnimation {
            initializationState = hasExistingPin ? .requiresPinAuthentication : .requiresPinCreation
            authenticationFlow = .loggedInNeedsPin(hasExistingPin: hasExistingPin)
        }
    }
    
    func setUnauthenticated() {
        withAnimation {
            initializationState = .unauthenticated
            authenticationFlow = .loggedOut
        }
    }
    
    func setError(_ message: String) {
        withAnimation {
            initializationState = .error(message)
        }
    }
    
    func reset() {
        withAnimation {
            initializationState = .unauthenticated
            authenticationFlow = .loggedOut
        }
    }
}

// MARK: - State Extensions
extension AppStateManager {
    var isAuthenticatedUser: Bool {
        if case .fullyAuthenticated = authenticationFlow {
            return true
        }
        return false
    }
    
    var requiresPinInput: Bool {
        switch initializationState {
        case .requiresPinCreation, .requiresPinAuthentication:
            return true
        default:
            return false
        }
    }
    
    var isInLoadingState: Bool {
        switch initializationState {
        case .splash, .loading:
            return true
        default:
            return false
        }
    }
}
