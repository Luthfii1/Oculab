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
                        icon: AppText.Icon.personFill,
                        title: AppText.Profile.accountInfoTitle,
                        isExtendable: false,
                        data: [
                            (key: AppText.Profile.emailKey, value: authPresenter.user.email ?? authPresenter.user.name),
                            (key: AppText.Profile.roleKey, value: authPresenter.user.role.rawValue.capitalized),
                            (key: AppText.Profile.jobTitleKey, value: AppText.Profile.jobTitleValue),
                            (key: AppText.Profile.healthFacilityKey, value: authPresenter.user.healthFacilityName ?? AppText.Profile.healthFacilityDefault),
                        ],
                        titleSize: AppTypography.s4_1,
                        titleCard: authPresenter.user.name
                    )

                    if authPresenter.user.role == .ADMIN {
                        AppButton(
                            title: AppText.Profile.accountManagementButton,
                            leftIcon: AppText.Icon.personFill,
                            rightIcon: AppText.Icon.arrowRight,
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
                        title: AppText.Profile.editPasswordButton,
                        leftIcon: AppText.Icon.lock,
                        rightIcon: AppText.Icon.arrowRight,
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
                        title: AppText.Profile.editPinButton,
                        leftIcon: AppText.Icon.lockCircleDotted,
                        rightIcon: AppText.Icon.arrowRight,
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

                    if authPresenter.isFaceIdAvailable {
                        HStack {
                            Image(systemName: AppText.Icon.faceId)
                                .foregroundColor(AppColors.purple500)
                            Toggle(AppText.Profile.faceIdToggle, isOn: Binding(
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

                    AppButton(
                        title: AppText.Profile.privacyPolicyButton,
                        leftIcon: AppText.Icon.lockShield,
                        rightIcon: AppText.Icon.arrowRight,
                        colorType: .tertiary,
                        titleColor: AppColors.slate900
                    ) {
                        Router.shared.navigateTo(.kebijakanPrivasi)
                    }
                    .padding(.vertical, Decimal.d16)
                    .background(.white)
                    .cornerRadius(Decimal.d12)
                    .overlay(
                        RoundedRectangle(cornerRadius: Decimal.d12)
                            .stroke(AppColors.slate100)
                    )

                    AppButton(title: AppText.Profile.logoutButton, rightIcon: AppText.Icon.doorRightHandOpen, colorType: .destructive(.secondary)) {
                        profilePresenter.logout()
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle(AppText.Profile.navigationTitle)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(DependencyInjection.shared.createProfilePresenter())
        .environmentObject(DependencyInjection.shared.createAuthPresenter())
}
