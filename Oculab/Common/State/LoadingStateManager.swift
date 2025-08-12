//
//  LoadingStateManager.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 12/08/25.
//

import Foundation
import SwiftUI

// MARK: - Loading State Types
enum LoadingState {
    case idle
    case loading(String?)
    case success(String?)
    case error(String)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var message: String? {
        switch self {
        case .idle:
            return nil
        case .loading(let message):
            return message ?? "loading.default_message".localized
        case .success(let message):
            return message
        case .error(let message):
            return message
        }
    }
}

// MARK: - Loading State Manager
@MainActor
class LoadingStateManager: ObservableObject {
    @Published var currentState: LoadingState = .idle
    
    func setLoading(_ message: String? = nil) {
        currentState = .loading(message)
    }
    
    func setSuccess(_ message: String? = nil) {
        currentState = .success(message)
        
        // Auto-reset to idle after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.setIdle()
        }
    }
    
    func setError(_ message: String) {
        currentState = .error(message)
    }
    
    func setIdle() {
        currentState = .idle
    }
    
    // Convenience computed properties
    var isLoading: Bool {
        currentState.isLoading
    }
    
    var message: String? {
        currentState.message
    }
}
