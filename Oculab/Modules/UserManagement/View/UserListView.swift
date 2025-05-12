//
//  UserListView.swift
//  Oculab
//
//  Created by Risa on 11/05/25.
//

import SwiftUI

struct UserListView: View {
    var onTapMore: (String) -> Void
    
    @ObservedObject private var presenter = AccountPresenter()
    
    let groupedAccounts: [String: [String]] = [
        "A": ["Adinda Putri Maharani", "Ahmad Fahri Rahman"],
        "B": ["Brigitta Maharani Wijaya", "Budianto Santoso", "Bulan Purnama Sari"]
    ]

    var sortedKeys: [String] {
        groupedAccounts.keys.sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(sortedKeys, id: \.self) { key in
                VStack(alignment: .leading, spacing: 8) {
                    Text(key)
                        .font(AppTypography.s4_1)
                        .foregroundColor(AppColors.slate400)
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        if let accounts = presenter.groupedAccounts[key] {
                            ForEach(accounts, id: \.id) { account in
                                HStack {
                                    Text(account.name)
                                        .font(AppTypography.p2)
                                        .foregroundColor(AppColors.slate900)
                                    
                                    Spacer()
                                    
                                    Button {
                                        onTapMore(account.name)
                                    } label: {
                                        Image(systemName: "ellipsis")
                                            .foregroundColor(AppColors.slate400)
                                    }
                                }
                                .padding(.vertical, 12)
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
        .onAppear {
            Task {
                await presenter.fetchAllAccount()
            }
        }
    }
}


//#Preview {
////    UserListView.(onTapMore: .constant({}))
//}
