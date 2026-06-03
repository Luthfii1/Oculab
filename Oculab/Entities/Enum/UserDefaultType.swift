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
    /// True after PIN/Face ID succeeds for the current login session; cleared on logout.
    case isPinSessionAuthorized
    /// Tracks SwiftData schema generation; bump to wipe local store on breaking model changes.
    case swiftDataSchemaVersion
}
