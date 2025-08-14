//
//  LocalizationHelper.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 05/08/25.
//

import Foundation

// MARK: - Localization Helper
extension String {
    /// Returns the localized string for the current key
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Returns the localized string with arguments
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}

// MARK: - Convenient Localization Functions
func L(_ key: String) -> String {
    return key.localized
}

func L(_ key: String, _ arguments: CVarArg...) -> String {
    return key.localized(with: arguments)
}
