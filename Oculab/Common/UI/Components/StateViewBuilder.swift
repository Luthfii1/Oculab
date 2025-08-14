//
//  StateViewBuilder.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 12/08/25.
//

import SwiftUI

// MARK: - State View Builder
struct StateViewBuilder<Content: View, LoadingContent: View, ErrorContent: View>: View {
    let loadingState: LoadingState
    @ViewBuilder let content: () -> Content
    @ViewBuilder let loadingContent: () -> LoadingContent
    @ViewBuilder let errorContent: (String) -> ErrorContent
    
    var body: some View {
        Group {
            switch loadingState {
            case .idle:
                content()
                
            case .loading(_):
                loadingContent()
                
            case .success(_):
                content()
                
            case .error(let message):
                errorContent(message)
            }
        }
        .animation(.easeInOut(duration: AppConstants.animationDuration), value: loadingState)
    }
}

// MARK: - Convenience Initializers
extension StateViewBuilder where LoadingContent == LoadingView, ErrorContent == ErrorView {
    init(
        loadingState: LoadingState,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.loadingState = loadingState
        self.content = content
        self.loadingContent = { LoadingView() }
        self.errorContent = { message in ErrorView(message: message) }
    }
    
    init(
        loadingState: LoadingState,
        loadingTitle: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.loadingState = loadingState
        self.content = content
        self.loadingContent = { LoadingView(title: loadingTitle, showLogo: false) }
        self.errorContent = { message in ErrorView(message: message) }
    }
}

// MARK: - Error View Component  
struct ErrorView: View {
    let message: String
    let onRetry: (() -> Void)?
    
    init(message: String, onRetry: (() -> Void)? = nil) {
        self.message = message
        self.onRetry = onRetry
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Error icon
            Image(systemName: AppIcon.warning)
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            // Error message
            Text(message)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Retry button (optional)
            if let onRetry = onRetry {
                Button(action: onRetry) {
                    Label(
                        AppAction.retry,
                        systemImage: AppIcon.refresh
                    )
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(AppConstants.cornerRadius)
                }
            }
        }
        .padding()
    }
}

// MARK: - Preview
#Preview {
    VStack {
        StateViewBuilder(
            loadingState: .loading(nil),
            content: {
                Text("Content View")
                    .font(.title)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.green.opacity(0.2))
            }
        )
        .frame(height: 200)
        
        Divider()
        
        StateViewBuilder(
            loadingState: .error(AppValue.unknownError),
            content: {
                Text("Content View")
                    .font(.title)
            }
        )
        .frame(height: 200)
    }
}
