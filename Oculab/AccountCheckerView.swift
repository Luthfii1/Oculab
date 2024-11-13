//
//  AccountCheckerView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/11/24.
//

import SwiftUI

struct AccountCheckerView: View {
    @AppStorage(UserDefaultType.isUserLoggedIn.rawValue) var isUserLoggedIn: Bool = false
    @StateObject private var securityPresenter = AuthenticationPresenter()
    @State private var isSplashScreenVisible = true

    var body: some View {
        RouterView {
            if isSplashScreenVisible {
                SplashScreenView()
            } else {
                if isUserLoggedIn {
                    ContentView()
                        .environmentObject(securityPresenter)
                } else {
                    LoginView()
                        .environmentObject(securityPresenter)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    isSplashScreenVisible = false
                }
            }
        }
        .environmentObject(Router.shared)
    }
}

#Preview {
    AccountCheckerView()
}
