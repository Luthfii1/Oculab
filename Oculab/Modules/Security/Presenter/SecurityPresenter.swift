//
//  SecurityPresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 06/11/24.
//

import Foundation

class SecurityPresenter: ObservableObject {
    @Published var pin: String = ""
    @Published var firstPin: String = ""
    @Published var secondPin: String = ""
    @Published var isOpeningApp: Bool = false

    func setPassword() {
        UserDefaults.standard.set(secondPin, forKey: "pinUserDefaults")
    }

    func isValidPin() -> Bool {
        return UserDefaults.standard.string(forKey: "pinUserDefaults") == pin
    }

    func confirmedPin() -> Bool {
        return firstPin == secondPin
    }
}
