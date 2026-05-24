//
//  UserDefaultType.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/11/24.
//

import Foundation

enum UserDefaultType: String, CaseIterable {
    case isUserLoggedIn
    case userId
    case accessPin
    case isFaceIdEnabled
    case hasSeenOnboarding
    case firstTimeLogin
}
