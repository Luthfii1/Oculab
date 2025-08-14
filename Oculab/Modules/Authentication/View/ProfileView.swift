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
                                            await authPresenter.requestFaceIDActivation()
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
                        AppButton(
                            title: AppNav.accountManagement,
                            leftIcon: AppIcon.personFill,
                            rightIcon: AppIcon.arrowRight,
                            colorType: .tertiary,
                            titleColor: AppColors.slate900
                        ) {
                            profilePresenter.navigateTo(.accountManagement)
                        }
                        .padding(.vertical, Decimal.d16)
                        .background(.white)
                        .cornerRadius(Decimal.d12)
                        .overlay(
                            RoundedRectangle(cornerRadius: Decimal.d12)
                                .stroke(AppColors.slate100)
                        )
                    }

                    AppButton(
                        title: AppTextAuthProfile.editPasswordButton,
                        leftIcon: AppIcon.lock,
                        rightIcon: AppIcon.arrowRight,
                        colorType: .tertiary,
                        titleColor: AppColors.slate900
                    ) {
                        profilePresenter.navigateTo(.editPassword)
                    }
                    .padding(.vertical, Decimal.d16)
                    .background(.white)
                    .cornerRadius(Decimal.d12)
                    .overlay(
                        RoundedRectangle(cornerRadius: Decimal.d12)
                            .stroke(AppColors.slate100)
                    )

                    AppButton(
                        title: AppTextAuthProfile.editPinButton,
                        leftIcon: AppIcon.lockCircleDotted,
                        rightIcon: AppIcon.arrowRight,
                        colorType: .tertiary,
                        titleColor: AppColors.slate900
                    ) {
                        profilePresenter.navigateTo(.userAccessPin(state: .changePIN))
                    }
                    .padding(.vertical, Decimal.d16)
                    .background(.white)
                    .cornerRadius(Decimal.d12)
                    .overlay(
                        RoundedRectangle(cornerRadius: Decimal.d12)
                            .stroke(AppColors.slate100)
                    )

                    AppButton(
                        title: AppTextAuthProfile.privacyPolicyButton,
                        leftIcon: AppIcon.lockShield,
                        rightIcon: AppIcon.arrowRight,
                        colorType: .tertiary,
                        titleColor: AppColors.slate900
                    ) {
                        Router.shared.navigateTo(.privacyPolicy)
                    }
                    .padding(.vertical, Decimal.d16)
                    .background(.white)
                    .cornerRadius(Decimal.d12)
                    .overlay(
                        RoundedRectangle(cornerRadius: Decimal.d12)
                            .stroke(AppColors.slate100)
                    )

                    AppButton(title: AppAction.exit, rightIcon: AppIcon.doorRightHandOpen, colorType: .destructive(.secondary)) {
                        Task {
                            await profilePresenter.logout()
                        }
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle(AppNav.profile)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(DependencyInjection.shared.createProfilePresenter())
        .environmentObject(DependencyInjection.shared.createAuthPresenter())
}
