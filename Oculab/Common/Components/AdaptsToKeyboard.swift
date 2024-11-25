//
//  AdaptsToKeyboard.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/11/24.
//

import Combine
import SwiftUI

@MainActor
struct AdaptsToKeyboard: ViewModifier {
    @Binding var isKeyboardVisible: Bool
    @State private var currentHeight: CGFloat = 0
    @MainActor
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .padding(.bottom, self.currentHeight)
                .onAppear {
                    NotificationCenter.Publisher(
                        center: NotificationCenter.default,
                        name: UIResponder.keyboardWillShowNotification
                    )
                    .merge(with: NotificationCenter.Publisher(
                        center: NotificationCenter.default,
                        name: UIResponder.keyboardWillChangeFrameNotification
                    ))
                    .compactMap { notification in
                        withAnimation(.easeOut(duration: 0.16)) {
                            notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                        }
                    }
                    .map { rect in
                        self.isKeyboardVisible = true
                        return rect.height - geometry.safeAreaInsets.bottom
                    }
                    .subscribe(Subscribers.Assign(object: self, keyPath: \.currentHeight))
                    NotificationCenter.Publisher(
                        center: NotificationCenter.default,
                        name: UIResponder.keyboardWillHideNotification
                    )
                    .map { _ in
                        self.isKeyboardVisible = false
                        return CGFloat.zero
                    }
                    .subscribe(Subscribers.Assign(object: self, keyPath: \.currentHeight))
                }
        }
    }
}

extension View {
    @MainActor
    func adaptsToKeyboard(isKeyboardVisible: Binding<Bool>) -> some View {
        modifier(AdaptsToKeyboard(isKeyboardVisible: isKeyboardVisible))
    }
}
