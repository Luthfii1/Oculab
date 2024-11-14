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
}
