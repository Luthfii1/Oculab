//
//  RegisterEntryComponent.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 20/08/25.
//

import SwiftUI

struct RegisterEntryComponent: View {
    let onB2C: () -> Void
    let onB2B: () async -> Void
    @State private var isLoadingB2B = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Card at the very top, minimal top padding
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [AppColors.purple50, AppColors.slate0]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing)
                    )
                    .shadow(color: AppColors.purple100.opacity(0.18), radius: 10, x: 0, y: 4)
                VStack(spacing: 10) {
                    Image(AppImage.addAccount)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(AppColors.purple500)
                    Text(AppTextAuthRegister.entryTitle)
                        .font(AppTypography.h4)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppColors.purple500)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 18)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)

            Spacer(minLength: 0)

            VStack {
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 28) {
                    // B2C (Individual) - Focused
                    VStack(alignment: .leading, spacing: 12) {
                        AppButton(
                            title: AppTextAuthRegister.entryIndividualButton,
                            colorType: .primary,
                            size: .large,
                            isEnabled: true
                        ) {
                            onB2C()
                        }
                        Text(AppTextAuthRegister.entryIndividualDescription)
                            .font(AppTypography.p2)
                            .foregroundStyle(AppColors.slate700)
                            .padding(.leading, 4)
                            .multilineTextAlignment(.leading)
                    }
                    // Divider with "or"
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(AppColors.slate200)
                        Text(AppAction.or)
                            .font(AppTypography.p1)
                            .foregroundStyle(AppColors.slate400)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(AppColors.slate200)
                    }
                    // B2B (Health Facility)
                    VStack(alignment: .leading, spacing: 12) {
                        AppButton(
                            title: AppTextAuthRegister.entryHealthFacilityButton,
                            colorType: .secondary,
                            size: .large,
                            isEnabled: !isLoadingB2B
                        ) {
                            isLoadingB2B = true
                            Task {
                                await onB2B()
                                isLoadingB2B = false
                            }
                        }
                        Text(AppTextAuthRegister.entryHealthFacilityDescription)
                            .font(AppTypography.p2)
                            .foregroundStyle(AppColors.slate700)
                            .padding(.leading, 4)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(.horizontal, 24)
                Spacer(minLength: 0)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
