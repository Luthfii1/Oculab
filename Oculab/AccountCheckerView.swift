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
            currentView
        }
        .onAppear(perform: initializeApp)
        .environmentObject(Router.shared)
    }
}

// MARK: - View Builder
private extension AccountCheckerView {
    @ViewBuilder
    var currentView: some View {
        if authPresenter.isSplashScreenVisible {
            SplashScreenView()
        } else if isInitializing {
            loadingView
        } else {
            mainContentView
        }
    }
    
    var loadingView: some View {
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
    }
    
    @ViewBuilder
    var mainContentView: some View {
        if isUserLoggedIn {
            authenticatedUserView
        } else {
            LoginView()
                .environmentObject(authPresenter)
        }
    }
    
    @ViewBuilder
    var authenticatedUserView: some View {
        if authPresenter.isPinAuthorized {
            ContentView()
                .environmentObject(authPresenter)
        } else {
            pinInputView
        }
    }
    
    @ViewBuilder
    var pinInputView: some View {
        let pinState: PinMode = authPresenter.user.accessPin == nil ? .create : .authenticate
        UserAccessPinView(state: pinState)
            .environmentObject(authPresenter)
    }
}
// MARK: - Initialization Logic
private extension AccountCheckerView {
    func initializeApp() {
        startSplashScreenTimer()
        Task {
            await initializeUserState()
        }
    }
    
    func startSplashScreenTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                authPresenter.isSplashScreenVisible = false
            }
        }
    }
    
    @MainActor
    func initializeUserState() async {
        defer { isInitializing = false }
        
        guard authPresenter.isUserLoggedIn() else {
            authPresenter.isPinAuthorized = false
            return
        }
        
        await authPresenter.getAccountById()
    }
}

#Preview {
    AccountCheckerView()
        .environmentObject(DependencyInjection.shared.createAuthPresenter())
}
