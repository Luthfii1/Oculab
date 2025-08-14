//
//  LoadingView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 12/08/25.
//

import SwiftUI

// MARK: - Loading View Component
struct LoadingView: View {
    let title: String
    let showLogo: Bool
    
    init(
        title: String = "loading.title".localized,
        showLogo: Bool = true
    ) {
        self.title = title
        self.showLogo = showLogo
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.primary.opacity(0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Logo (optional)
                if showLogo {
                    logoView
                }
                
                // Loading indicator
                loadingIndicator
                
                // Title
                titleView
            }
        }
    }
    
    // MARK: - View Components
    private var logoView: some View {
        Image(AppImage.logo)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadius))
    }
    
    private var loadingIndicator: some View {
        ProgressView()
            .scaleEffect(AppConstants.loadingIndicatorScale)
            .tint(.blue)
    }
    
    private var titleView: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
            .multilineTextAlignment(.center)
    }
}

// MARK: - Loading View Variants
extension LoadingView {
    static var splash: LoadingView {
        LoadingView(
            title: "splash.title".localized,
            showLogo: true
        )
    }
    
    static var authentication: LoadingView {
        LoadingView(
            title: "loading.authentication".localized,
            showLogo: false
        )
    }
    
    static var dataLoading: LoadingView {
        LoadingView(
            title: "loading.data".localized,
            showLogo: false
        )
    }
}

// MARK: - Preview
#Preview {
    VStack {
        LoadingView.splash
            .frame(height: 200)
        
        Divider()
        
        LoadingView.authentication
            .frame(height: 150)
        
        Divider()
        
        LoadingView.dataLoading
            .frame(height: 100)
    }
}
