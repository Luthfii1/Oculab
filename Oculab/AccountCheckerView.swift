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
    @State private var isInitializing = true

    var body: some View {
        RouterView {
            if authPresenter.isSplashScreenVisible {
                SplashScreenView()
            } else if isInitializing {
                // Show loading state while checking user authentication
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                    Text(AppState.loading("user data"))
                        .font(AppTypography.p3)
                        .foregroundColor(AppColors.slate600)
                        .padding(.top, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.slate50)
            } else {
                if isUserLoggedIn {
                    if authPresenter.isPinAuthorized {
                        ContentView()
                            .environmentObject(authPresenter)
                    } else {
                        // Show PIN input based on whether user has PIN or not
                        if authPresenter.user.accessPin == nil {
                            UserAccessPinView(state: .create)
                                .environmentObject(authPresenter)
                        } else {
                            UserAccessPinView(state: .authenticate)
                                .environmentObject(authPresenter)
                        }
                    }
                } else {
                    LoginView()
                        .environmentObject(authPresenter)
                }
            }
        }
        .onAppear {
            initializeApp()
        }
        .environmentObject(Router.shared)
    }
    
    private func initializeApp() {
        // Show splash screen for 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                authPresenter.isSplashScreenVisible = false
            }
        }
        
        // Initialize user authentication state
        Task {
            await initializeUserState()
        }
    }
    
    @MainActor
    private func initializeUserState() async {
        defer {
            isInitializing = false
        }
        
        // Check if user is logged in
        guard authPresenter.isUserLoggedIn() else {
            // User is not logged in, clear any stale state
            authPresenter.isPinAuthorized = false
            return
        }
        
        // User is logged in, get account data
        await authPresenter.getAccountById()
    }
}

#Preview {
    AccountCheckerView()
        .environmentObject(DependencyInjection.shared.createAuthPresenter())
}
