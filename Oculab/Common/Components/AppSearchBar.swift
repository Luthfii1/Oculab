//
//  AppSearchBar.swift
//  Oculab
//
//  Created by Risa on 11/05/25.
//

import SwiftUI

struct AppSearchBar: View {
    @Binding var searchText: String
    var placeholder: String = "Cari akun"
    var onSearch: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.slate400)

                TextField(placeholder, text: $searchText)
                    .font(AppTypography.p2)
                    .foregroundColor(AppColors.slate900)
            }
            .frame(minWidth: 250, minHeight: 32)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppColors.slate0)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.slate200, lineWidth: 1)
            )
            .cornerRadius(12)

            AppButton(
                title: "Cari",
                cornerRadius: 12,
                action: {
                    onSearch()
                }
            )
        }
    }
}

#Preview {
    AppSearchBar(
        searchText: .constant("Search"),
        onSearch: {}
    )
}
