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

    // MARK: - Core Dependencies
    private var modelContext: ModelContext?
    
    // MARK: - Network Dependencies
    lazy var networkRetryManager: NetworkRetryManager = NetworkRetryManager()
    lazy var networkService: NetworkServiceProtocol = {
        NetworkService(retryManager: networkRetryManager)
    }()
    
    // MARK: - Stored Properties for All Modules
    private var authenticationPresenterInstance: AuthenticationPresenter?
    lazy var authenticationInteractor: AuthenticationInteractor = {
        AuthenticationInteractor(
            modelContext: safeModelContext,
            networkService: networkService
        )
    }()
    lazy var profileInteractor: ProfileInteractor = ProfileInteractor(networkService: networkService)
    lazy var accountInteractor: AccountInteractor = {
        AccountInteractor(
            authInteractor: authenticationInteractor,
            authPresenter: createAuthPresenter(),
            networkService: networkService
        )
    }()
    lazy var examInteractor: ExamInteractor = {
        ExamInteractor(networkService: networkService)
    }()
    
    func initializer(modelContext: ModelContext) {
        self.modelContext = modelContext
        VideoUploadQueueService.shared.configure(
            modelContext: modelContext,
            examInteractor: examInteractor,
            networkRetryManager: networkRetryManager
        )
    }
    
    // MARK: - Computed Properties
    private var safeModelContext: ModelContext {
        guard let modelContext = modelContext else {
            fatalError("ModelContext not initialized. Call initializer(modelContext:) first.")
        }
        return modelContext
    }
}

// MARK: - Authentication Module
extension DependencyInjection {
    func createAuthPresenter() -> AuthenticationPresenter {
        if let existing = authenticationPresenterInstance {
            return existing
        }
        let presenter = AuthenticationPresenter(interactor: authenticationInteractor)
        authenticationPresenterInstance = presenter
        return presenter
    }
}

// MARK: - Profile Module
extension DependencyInjection {
    func createProfilePresenter() -> ProfilePresenter {
        return ProfilePresenter(
            interactor: profileInteractor,
            authInteractor: authenticationInteractor
        )
    }
}

// MARK: - Account Management Module
extension DependencyInjection {
    func createAccountPresenter() -> AccountPresenter {
        return AccountPresenter(interactor: accountInteractor)
    }
}

// MARK: - Examination Module
extension DependencyInjection {
    func createExamDataPresenter() -> ExamDataPresenter {
        return ExamDataPresenter(interactor: examInteractor)
    }
}
