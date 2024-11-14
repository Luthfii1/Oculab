//
//  AccountCheckerView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/11/24.
//

import SwiftUI

struct AccountCheckerView: View {
    @AppStorage(UserDefaultType.isUserLoggedIn.rawValue) var isUserLoggedIn: Bool = false
    @EnvironmentObject var dependencyInjection: DependencyInjection
    @State private var isSplashScreenVisible = true

    var body: some View {
        RouterView {
            if isSplashScreenVisible {
                SplashScreenView()
            } else {
                if isUserLoggedIn {
                    ContentView()
                        .environmentObject(dependencyInjection.createAuthPresenter())
                } else {
                    LoginView()
                        .environmentObject(dependencyInjection.createAuthPresenter())
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
