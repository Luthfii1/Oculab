//
//  ValidationFieldErrorView.swift
//  Oculab
//

import SwiftUI

/// Inline validation message for fields that are not `ValidatedTextField` (e.g. radio groups).
struct ValidationFieldErrorView: View {
    let fieldName: String
    var showsErrors: Bool
    @ObservedObject var validationManager: ValidationManager

    var body: some View {
        if showsErrors, let message = validationManager.getError(for: fieldName) {
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: AppIcon.alert)
                    .foregroundColor(AppColors.red500)
                    .font(.caption)
                Text(message)
                    .font(AppTypography.p3)
                    .foregroundColor(AppColors.red500)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 4)
        }
    }
}
