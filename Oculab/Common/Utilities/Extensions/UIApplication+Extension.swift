//
//  UIApplication+Extension.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 24/05/25.
//

import SwiftUI
import UIKit

extension UIApplication {
    // Add this extension to handle keyboard dismissal
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
