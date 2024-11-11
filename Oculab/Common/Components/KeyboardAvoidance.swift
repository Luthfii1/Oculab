//
//  KeyboardAvoidance.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/11/24.
//

import Combine
import SwiftUI

struct KeyboardAvoidance: ViewModifier {
    @State private var currentHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .padding(.bottom, currentHeight)
            .onReceive(Publishers.keyboardHeight) { keyboardHeight in
                withAnimation {
                    currentHeight = keyboardHeight
                }
            }
    }
}
