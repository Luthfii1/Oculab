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

    var body: some View {
        RouterView {
            if authPresenter.isSplashScreenVisible {
                SplashScreenView()
            } else {
                if isUserLoggedIn {
                    if authPresenter.isPinAuthorized {
                        ContentView()
                            .environmentObject(authPresenter)
                    } else {
                        UserAccessPinView(state: .authenticate)
                            .environmentObject(authPresenter)
                    }
                } else {
                    LoginView()
                        .environmentObject(authPresenter)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    authPresenter.isSplashScreenVisible = false
                }
            }
            Task {
                if authPresenter.isUserLoggedIn() {
                    await authPresenter.getAccountById()
                } else {
                    // User is not logged in, redirect to login
                    Router.shared.navigateTo(.login)
                }
            }
        }
        .environmentObject(Router.shared)
    }
}

#Preview {
    AccountCheckerView()
        .environmentObject(DependencyInjection.shared.createAuthPresenter())
}
