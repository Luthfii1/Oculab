import SwiftUI
import UIKit

public class KeyboardManager {
    public static let shared = KeyboardManager()
    
    private init() {
        setupKeyboardDismissal()
    }
    
    private func setupKeyboardDismissal() {
        // Add tap gesture to window
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            tapGesture.cancelsTouchesInView = false
            window.addGestureRecognizer(tapGesture)
        }
    }
    
    @objc private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// SwiftUI View extension to make it easier to use
public extension View {
    func dismissKeyboardOnTap() -> some View {
        self.onAppear {
            _ = KeyboardManager.shared
        }
    }
} 
