//
//  ProfileView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 14/11/24.
//

import LocalAuthentication
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authPresenter: AuthenticationPresenter
    @EnvironmentObject private var profilePresenter: ProfilePresenter

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .center, spacing: 20) {
                    if !authPresenter.canPerformClinicalActions {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(AppTextAuthProfile.verifyEmailBannerTitle)
                                .font(AppTypography.s4)
                                .foregroundStyle(AppColors.slate900)
                            Text(AppTextAuthProfile.verifyEmailBannerMessage)
                                .font(AppTypography.p3)
                                .foregroundStyle(AppColors.slate600)
                            if !authPresenter.verificationResendMessage.isEmpty {
                                Text(authPresenter.verificationResendMessage)
                                    .font(AppTypography.p4)
                                    .foregroundStyle(AppColors.purple600)
                            }
                            if !authPresenter.emailVerificationRefreshError.isEmpty {
                                Text(authPresenter.emailVerificationRefreshError)
                                    .font(AppTypography.p4)
                                    .foregroundStyle(AppColors.slate600)
                            }
                            AppButton(
                                title: authPresenter.isRefreshingEmailVerification
                                    ? AppState.loading
                                    : AppTextAuthProfile.verifyEmailRefreshButton,
                                colorType: .secondary,
                                size: .large,
                                isEnabled: !authPresenter.isRefreshingEmailVerification
                            ) {
                                Task { await authPresenter.refreshEmailVerificationStatus() }
                            }
                            AppButton(
                                title: authPresenter.isResendingVerification
                                    ? AppState.loading
                                    : AppTextAuthProfile.verifyEmailResendButton,
                                colorType: .secondary,
                                size: .large,
                                isEnabled: !authPresenter.isResendingVerification
                            ) {
                                Task {
                                    await authPresenter.resendEmailVerification()
                                }
                            }
                        }
                        .padding(AppConstants.defaultPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.purple50)
                        .cornerRadius(AppConstants.cornerRadius)
                        .accessibilityElement(children: .contain)
                    }

                    ExtendableCard(
                        icon: AppIcon.personFill,
                        title: AppTextAuthProfile.accountInfoTitle,
                        isExtendable: false,
                        data: [
                            (key: AppLabel.email, value: authPresenter.user.email ?? authPresenter.user.name),
                            (key: AppLabel.role, value: authPresenter.user.role.rawValue.capitalized),
                            (key: AppTextAuthProfile.jobTitleKey, value: AppTextAuthProfile.jobTitleValue),
                            (key: AppTextAuthProfile.healthFacilityKey, value: authPresenter.user.healthFacilityName ?? AppState.notAvailable),
                        ],
                        titleSize: AppTypography.s4_1,
                        titleCard: authPresenter.user.name
                    )

                    // Network Status Section
                    HStack {
                        Image(systemName: AppNetworkIcon.network)
                            .foregroundColor(AppColors.purple500)
                            .font(AppTypography.s5)
                        
                        Text(AppNetwork.status)
                            .font(AppTypography.s5)
                            .foregroundColor(AppColors.slate900)
                        
                        Spacer()
                        
                        NetworkStatusView()
                    }
                    .padding(AppConstants.defaultPadding)
                    .background(.white)
                    .cornerRadius(AppConstants.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                            .stroke(AppColors.slate100)
                    )

                    if authPresenter.isFaceIdAvailable {
                        HStack {
                            Image(systemName: AppIcon.faceId)
                                .foregroundColor(AppColors.purple500)
                            Toggle(AppTextAuthProfile.faceIdToggle, isOn: Binding(
                                get: { authPresenter.isFaceIdEnabledFromUserDefaults },
                                set: { newValue in
                                    Task {
                                        if newValue {
                                            let enabled = await authPresenter.requestFaceIDActivation()
                                            if !enabled {
                                                authPresenter.updateFaceIdPreference(false)
                                            }
                                        } else {
                                            authPresenter.updateFaceIdPreference(false)
                                        }
                                    }
                                }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: AppColors.purple500))
                            .font(AppTypography.s5)
                        }
                        .padding(.vertical, Decimal.d16)
                        .padding(.horizontal, 16)
                        .background(.white)
                        .cornerRadius(Decimal.d12)
                        .overlay(
                            RoundedRectangle(cornerRadius: Decimal.d12)
                                .stroke(AppColors.slate100)
                        )
                    }

                    if authPresenter.user.role == .ADMIN {
                        ProfileActionRow(
                            title: AppNav.accountManagement,
                            icon: AppIcon.personFill
                        ) {
                            profilePresenter.navigateTo(.accountManagement)
                        }
                    }

                    ProfileActionRow(
                        title: AppTextAuthProfile.editPasswordButton,
                        icon: AppIcon.lock
                    ) {
                        profilePresenter.navigateTo(.editPassword)
                    }

                    ProfileActionRow(
                        title: AppTextAuthProfile.editPinButton,
                        icon: AppIcon.lockCircleDotted
                    ) {
                        profilePresenter.navigateTo(.userAccessPin(state: .changePIN))
                    }

                    ProfileActionRow(
                        title: AppTextAuthProfile.privacyPolicyButton,
                        icon: AppIcon.lockShield
                    ) {
                        Router.shared.navigateTo(.privacyPolicy)
                    }

                    AppButton(title: AppAction.exit, rightIcon: AppIcon.doorRightHandOpen, colorType: .destructive(.secondary)) {
                        Task {
                            await profilePresenter.logout(authPresenter: authPresenter)
                        }
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle(AppNav.profile)
        }
        .task { await authPresenter.refreshEmailVerificationStatus() }
        .refreshable { await authPresenter.refreshEmailVerificationStatus() }
    }
}

struct ProfileActionRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .frame(width: 24)
                        .accessibilityHidden(true)
                }

                Text(title)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: AppIcon.arrowRight)
                        .font(.system(size: 16))
                        .accessibilityHidden(true)
                }
            }
            .font(AppTypography.s5)
            .foregroundStyle(AppColors.slate900)
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: Decimal.d12))
            .overlay {
                RoundedRectangle(cornerRadius: Decimal.d12)
                    .stroke(AppColors.slate100)
            }
            .contentShape(RoundedRectangle(cornerRadius: Decimal.d12))
        }
        .buttonStyle(ProfileActionButtonStyle())
    }
}

private struct ProfileActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.8 : 1)
    }
}

//#Preview {
//    ProfileView()
//        .environmentObject(DependencyInjection.shared.createProfilePresenter())
//        .environmentObject(DependencyInjection.shared.createAuthPresenter())
//}
