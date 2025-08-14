//
//  View+Extension.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 13/11/24.
//

import SwiftUI

struct HideBackButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
    }
}

extension View {
    func hideBackButton() -> some View {
        modifier(HideBackButton())
    }
}
