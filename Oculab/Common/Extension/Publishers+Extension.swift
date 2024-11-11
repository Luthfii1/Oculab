//
//  Publishers+Extension.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/11/24.
//

import Combine
import Foundation
import UIKit

// Extension to listen to the keyboard height
extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
            .map { notification -> CGFloat in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    return notification.name == UIResponder.keyboardWillHideNotification ? 0 : keyboardFrame.height
                }
                return 0
            }
            .eraseToAnyPublisher()
    }
}
