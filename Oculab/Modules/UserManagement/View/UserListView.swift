//
//  UserListView.swift
//  Oculab
//
//  Created by Risa on 11/05/25.
//

import SwiftUI

struct UserListView: View {
    @EnvironmentObject var presenter: AccountPresenter

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(presenter.displayedSortedGroupedAccounts, id: \.self) { key in
                VStack(alignment: .leading, spacing: 8) {
                    Text(key)
                        .font(AppTypography.s4_1)
                        .foregroundColor(AppColors.slate400)
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        if let accounts = presenter.displayedGroupedAccounts[key] {
                            ForEach(accounts, id: \.id) { account in
                                HStack {
                                    Button {
                                        if let account = presenter.findAccountById(account.id) {
                                            presenter.navigateTo(.editAccount(account: account))
                                        }
                                    } label: {
                                        HStack {
                                            Text(account.name)
                                                .font(AppTypography.p2)
                                                .foregroundColor(AppColors.slate900)

                                            Spacer()
                                        }
                                    }

                                    Button {
                                        presenter.selectUser(account)
                                    } label: {
                                        Image(systemName: "ellipsis")
                                            .foregroundColor(AppColors.slate400)
                                    }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal)

                                if account.id != accounts.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
}
