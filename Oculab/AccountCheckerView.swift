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
    @State private var isSplashScreenVisible = true

    var body: some View {
        RouterView {
            if isSplashScreenVisible {
                SplashScreenView()
            } else {
                if isUserLoggedIn {
                    if authPresenter.isPinAuthorized {
                        ContentView()
                            .environmentObject(authPresenter)
                    } else {
                        UserAccessPin(state: .authenticate)
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
                    isSplashScreenVisible = false
                }
            }
            Task {
                await authPresenter.getAccountById()
            }
        }
        .environmentObject(Router.shared)
    }
}

#Preview {
    AccountCheckerView()
        .environmentObject(DependencyInjection.shared.createAuthPresenter())
}
