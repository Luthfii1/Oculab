//
//  AccountCheckerView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/11/24.
//

import SwiftUI

struct AccountCheckerView: View {
    @AppStorage(UserDefaultType.isUserLoggedIn.rawValue) var isUserLoggedIn: Bool = false
    @State private var isSplashScreenVisible = true

    var body: some View {
        RouterView {
            if isSplashScreenVisible {
                SplashScreenView()
            } else {
                if isUserLoggedIn {
                    ContentView()
                } else {
                    LoginView()
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
