//
//  LoadingStateView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 19/12/24.
//

import SwiftUI

struct LoadingStateView: View {
    let isLoading: Bool
    let message: String?
    
    init(isLoading: Bool, message: String? = nil) {
        self.isLoading = isLoading
        self.message = message
    }
    
    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    if let message = message {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground).opacity(0.8))
            }
        }
    }
}

// MARK: - View Modifier for Loading States
struct LoadingOverlay: ViewModifier {
    let isLoading: Bool
    let message: String?
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LoadingStateView(isLoading: isLoading, message: message)
            )
            .disabled(isLoading)
    }
}

extension View {
    func loadingOverlay(_ isLoading: Bool, message: String? = nil) -> some View {
        modifier(LoadingOverlay(isLoading: isLoading, message: message))
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Content behind loading")
            .padding()
            .background(Color.blue.opacity(0.1))
            .loadingOverlay(true, message: "Loading data...")
        
        Text("Content without loading")
            .padding()
            .background(Color.green.opacity(0.1))
            .loadingOverlay(false)
    }
    .padding()
}
