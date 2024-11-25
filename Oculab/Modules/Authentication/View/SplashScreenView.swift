//
//  SplashScreenView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 06/11/24.
//

import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                Image(.logoSplashScreen)
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 48)

                Spacer()
            }
            .background(AppColors.purple500)
            .ignoresSafeArea(.all)
        }
    }
}

#Preview {
    SplashScreenView()
}
