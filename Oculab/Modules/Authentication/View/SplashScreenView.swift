//
//  SplashScreenView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 06/11/24.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()

                // Logo with subtle animation
                Image(AppImage.logoSplashScreen)
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 48)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Subtle loading indicator
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    
                    Text("Authenticating...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()
            }
            .background(AppColors.purple500)
            .ignoresSafeArea(.all)
            .onAppear {
                isAnimating = true
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
