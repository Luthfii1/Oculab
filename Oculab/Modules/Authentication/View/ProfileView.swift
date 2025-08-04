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
                        title: AppText.Authentication.ProfileView.accountInfoTitle,
                        isExtendable: false,
                        data: [
                            (key: AppText.Authentication.ProfileView.emailKey, value: authPresenter.user.email ?? authPresenter.user.name),
                            (key: AppText.Authentication.ProfileView.roleKey, value: authPresenter.user.role.rawValue.capitalized),
                            (key: AppText.Authentication.ProfileView.jobTitleKey, value: AppText.Authentication.ProfileView.jobTitleValue),
                            (key: AppText.Authentication.ProfileView.healthFacilityKey, value: authPresenter.user.healthFacilityName ?? AppText.Authentication.ProfileView.healthFacilityDefault),
                        ],
                        titleSize: AppTypography.s4_1,
                        titleCard: authPresenter.user.name
                    )

                    if authPresenter.user.role == .ADMIN {
                        AppButton(
                            title: AppText.Authentication.ProfileView.accountManagementButton,
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
                        title: AppText.Authentication.ProfileView.editPasswordButton,
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
                        title: AppText.Authentication.ProfileView.editPinButton,
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
                            Toggle(AppText.Authentication.ProfileView.faceIdToggle, isOn: Binding(
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
                        title: AppText.Authentication.ProfileView.privacyPolicyButton,
                        leftIcon: AppText.Icon.lockShield,
                        rightIcon: AppText.Icon.arrowRight,
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

                    AppButton(title: AppText.Authentication.ProfileView.logoutButton, rightIcon: AppText.Icon.doorRightHandOpen, colorType: .destructive(.secondary)) {
                        profilePresenter.logout()
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle(AppText.Authentication.ProfileView.navigationTitle)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(DependencyInjection.shared.createProfilePresenter())
        .environmentObject(DependencyInjection.shared.createAuthPresenter())
}
