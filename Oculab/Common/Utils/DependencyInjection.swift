//
//  DependencyInjection.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 13/11/24.
//

import Foundation
import SwiftData

class DependencyInjection: ObservableObject {
    static let shared = DependencyInjection()

    private init() {}

    private var modelContext: ModelContext?
    func initializer(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: Create Auth Presenter

    private var authenticationPresenterInstance: AuthenticationPresenter?
    lazy var authenticationInteractor: AuthenticationInteractor = .init(modelContext: modelContext!)
    func createAuthPresenter() -> AuthenticationPresenter {
        if let existing = authenticationPresenterInstance {
            return existing
        }
        let new = AuthenticationPresenter(interactor: authenticationInteractor)
        authenticationPresenterInstance = new
        return new
    }

    // MARK: Create Profile Presenter

    lazy var profileInteractor: ProfileInteractor = .init()
    func createProfilePresenter() -> ProfilePresenter {
        return ProfilePresenter(interactor: profileInteractor, authInteractor: authenticationInteractor)
    }
}
