//
//  RegisterUserView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 19/08/25.
//


import SwiftUI

struct RegisterUserView: View {
    @EnvironmentObject var presenter: AuthenticationPresenter

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    ValidatedTextField(
                        title: AppTextAuthRegister.fullNameTitle,
                        isRequired: true,
                        placeholder: AppTextAuthRegister.fullNamePlaceholder,
                        leftIcon: AppIcon.personFill,
                        text: $presenter.registerFullName,
                        fieldName: .registerFullName,
                        validationType: .name
                    )
                    ValidatedTextField(
                        title: AppTextAuthRegister.emailTitle,
                        isRequired: true,
                        placeholder: AppTextAuthRegister.emailPlaceholder,
                        leftIcon: AppIcon.envelope,
                        text: $presenter.registerEmail,
                        fieldName: .registerEmail,
                        validationType: .email
                    )
                    ValidatedTextField(
                        title: AppTextAuthRegister.healthFacilityNameTitle,
                        isRequired: true,
                        placeholder: AppTextAuthRegister.healthFacilityNamePlaceholder,
                        leftIcon: AppIcon.buildingFill,
                        text: $presenter.registerHealthFacilityName,
                        fieldName: .registerHealthFacilityName,
                        validationType: .required
                    )
                    AppDropdown(
                        title: AppTextAuthRegister.healthFacilityTypeTitle,
                        placeholder: AppTextAuthRegister.healthFacilityTypePlaceholder,
                        isRequired: true,
                        leftIcon: AppIcon.buildingCropCircle,
                        choices: HealthFacilityType.allCases.map { ($0.localized, $0.rawValue) },
                        isSearchEnabled: false,
                        selectedChoice: Binding<String>(
                            get: { presenter.registerHealthFacilityType?.rawValue ?? AppValue.empty },
                            set: { newValue in
                                presenter.registerHealthFacilityType = HealthFacilityType(rawValue: newValue)
                            }
                        )
                    )
                    AppButton(
                        title: AppTextAuthRegister.submitButton,
                        isEnabled: presenter.isRegisterFormValidAndFilled(),
                        action: {
                            Task {
                                await presenter.handleRegister()
                            }
                        }
                    )
                    HStack {
                        Spacer()
                        Text(AppTextAuthRegister.alreadyHaveAccount)
                            .font(AppTypography.p3)
                            .foregroundStyle(AppColors.slate900)
                        AppButton(
                            title: AppTextAuthRegister.loginHere,
                            colorType: .tertiary,
                            size: .large,
                            isEnabled: true
                        ) {
                            Task {
                                Router.shared.popToRoot()
                            }
                        }
                        .multilineTextAlignment(.leading)
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 32)
                .padding(.bottom, 32)
            }
            .navigationTitle(AppTextAuthRegister.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .dismissKeyboardOnTap()
            .alert(isPresented: $presenter.showRegisterSuccessAlert) {
                Alert(
                    title: Text(AppState.success),
                    message: Text(presenter.registerSuccessMessage),
                    dismissButton: .default(Text(AppAction.ok)) {
                        Router.shared.popToRoot()
                    }
                )
            }
        }
        .hideBackButton()
        .onDisappear {
            presenter.clearInput()
            presenter.clearValidationErrors()
        }
    }
}

#Preview {
    RegisterUserView()
        .environmentObject(DependencyInjection.shared.createAuthPresenter())
}
