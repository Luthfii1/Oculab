//
//  AppSearchBar.swift
//  Oculab
//
//  Created by Risa on 11/05/25.
//

import SwiftUI

struct AppSearchBar: View {
    @Binding var searchText: String
    var placeholder: String = AppSearch.placeholder
    var onSearch: () -> Void
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            stackedContent
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    searchField
                        .frame(minWidth: 160, idealWidth: 160, maxWidth: .infinity)
                    searchButton
                        .fixedSize(horizontal: true, vertical: false)
                }
                stackedContent
            }
        }
    }

    private var stackedContent: some View {
        VStack(spacing: 12) {
            searchField
            searchButton
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: AppIcon.search)
                .foregroundColor(AppColors.slate400)
                .accessibilityHidden(true)

            TextField(placeholder, text: $searchText)
                .font(AppTypography.p2)
                .foregroundColor(AppColors.slate900)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit(submitSearch)
                .accessibilityLabel(placeholder)

            if !searchText.isEmpty {
                Button {
                    searchText = AppValue.empty
                    isSearchFocused = true
                } label: {
                    Image(systemName: AppIcon.error)
                        .foregroundColor(AppColors.slate400)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppSearch.clearSearch)
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(AppColors.slate0, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.slate200, lineWidth: 1)
        }
    }

    private var searchButton: some View {
        AppButton(
            title: AppAction.search,
            cornerRadius: 12,
            action: submitSearch
        )
    }

    private func submitSearch() {
        isSearchFocused = false
        onSearch()
    }
}

#Preview {
    AppSearchBar(
        searchText: .constant("Search"),
        onSearch: {}
    )
}

#Preview("Narrow layout") {
    AppSearchBar(searchText: .constant("Rizky"), onSearch: {})
        .padding(24)
        .frame(width: 280)
}

#Preview("Accessibility text size") {
    AppSearchBar(searchText: .constant("Rizky"), onSearch: {})
        .environment(\.dynamicTypeSize, .accessibility3)
        .padding(24)
        .frame(width: 320)
}
