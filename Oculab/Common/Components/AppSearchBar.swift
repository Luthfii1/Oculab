//
//  AppSearchBar.swift
//  Oculab
//
//  Created by Risa on 11/05/25.
//

import SwiftUI
import UIKit

struct AppSearchBar: View {
    @Binding var searchText: String
    var placeholder: String = "Cari akun"
    var onSearch: () -> Void
    
    // Add this to observe changes in search text
    @State private var localSearchText: String = ""
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.slate400)

                // Use a local state binding first to avoid excessive presenter updates
                TextField(placeholder, text: $localSearchText)
                    .font(AppTypography.p2)
                    .foregroundColor(AppColors.slate900)
                    .onChange(of: localSearchText) { _, newValue in
                        // Update the actual binding
                        searchText = newValue
                    }
                
                // Add a clear button when text is not empty
                if !localSearchText.isEmpty {
                    Button(action: {
                        localSearchText = ""
                        searchText = ""
                        UIApplication.shared.endEditing()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.slate400)
                    }
                }
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
            // Update localSearchText when searchText changes externally
            .onAppear {
                localSearchText = searchText
            }
            .onChange(of: searchText) { _, newValue in
                if localSearchText != newValue {
                    localSearchText = newValue
                }
            }

            AppButton(
                title: "Cari",
                cornerRadius: 12,
                action: {
                    UIApplication.shared.endEditing()
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
