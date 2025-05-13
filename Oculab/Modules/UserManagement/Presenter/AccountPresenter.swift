//
//  AccountPresenter.swift
//  Oculab
//
//  Created by Risa on 11/05/25.
//

import Foundation

class AccountPresenter: ObservableObject {
    var interactor: AccountInteractor? = AccountInteractor()

    @Published var isUserLoading = false
    @Published var groupedAccounts: [String: [AccountResponse]] = [:]
    @Published var sortedGroupedAccounts: [String] = []

    func groupAccountsByName(accounts: [AccountResponse]) -> [String: [AccountResponse]] {
        var grouped: [String: [AccountResponse]] = [:]

        for account in accounts {
            guard let firstLetter = account.name.first?.uppercased() else { continue }
            grouped[firstLetter, default: []].append(account)
        }

        for key in grouped.keys {
            grouped[key]?.sort { $0.name < $1.name }
        }
        print("masuk groupaccount \(grouped)")

        return grouped
    }

    @MainActor
    func fetchAllAccount() async {
        isUserLoading = true
        defer { isUserLoading = false }

        do {
            let response = try await interactor?.getAllAccount()

            if let response {
                groupedAccounts = groupAccountsByName(accounts: response)
                sortedGroupedAccounts = groupedAccounts.keys.sorted()
            }

        } catch {
            // Handle error
            switch error {
            case let NetworkError.apiError(apiResponse):
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")

            case let NetworkError.networkError(message):
                print("Network error: \(message)")

            default:
                print("Unknown error: \(error.localizedDescription)")
            }
        }
    }

    func navigateTo(_ destination: Router.Route) {
        Router.shared.navigateTo(destination)
    }
}
