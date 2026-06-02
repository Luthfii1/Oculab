//
//  RegisterUserView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 19/08/25.
//


import SwiftUI

struct RegisterUserView: View {
    @EnvironmentObject var presenter: AuthenticationPresenter
    @StateObject private var contactPresenter = ContactPresenter(interactor: ContactInteractor())

    var body: some View {
        NavigationView {
            VStack {
                ScrollView(showsIndicators: false) {
                    if presenter.isChoosingRegistrationType {
                        RegisterEntryComponent(
                            onB2C: {
                                presenter.isChoosingRegistrationType = false
                            },
                            onB2B: {
                                await contactPresenter.directToWhatsapp()
                            }
                        )
                        .padding(.top, 8)
                    } else {
                        VStack(spacing: 24) {
                            ValidatedTextField(
                                title: AppTextAuthRegister.fullNameTitle,
                                isRequired: true,
                                placeholder: AppTextAuthRegister.fullNamePlaceholder,
                                leftIcon: AppIcon.personFill,
                                isDisabled: presenter.isLoading,
                                text: $presenter.registerFullName,
                                fieldName: .registerFullName,
                                validationType: .name
                            )
                            ValidatedTextField(
                                title: AppTextAuthRegister.emailTitle,
                                isRequired: true,
                                placeholder: AppTextAuthRegister.emailPlaceholder,
                                leftIcon: AppIcon.envelope,
                                isDisabled: presenter.isLoading,
                                text: $presenter.registerEmail,
                                fieldName: .registerEmail,
                                validationType: .email
                            )
                            ValidatedTextField(
                                title: AppTextAuthRegister.healthFacilityNameTitle,
                                isRequired: true,
                                placeholder: AppTextAuthRegister.healthFacilityNamePlaceholder,
                                leftIcon: AppIcon.buildingFill,
                                isDisabled: presenter.isLoading,
                                text: $presenter.registerHealthFacilityName,
                                fieldName: .registerHealthFacilityName,
                                validationType: .required
                            )
                            AppDropdown(
                                title: AppTextAuthRegister.healthFacilityTypeTitle,
                                placeholder: AppTextAuthRegister.healthFacilityTypePlaceholder,
                                isRequired: true,
                                leftIcon: AppIcon.buildingCropCircle,
                                isDisabled: presenter.isLoading,
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
                                title: presenter.registerButtonText,
                                isEnabled: presenter.isRegisterFormValidAndFilled() && !presenter.isLoading,
                                action: {
                                    Task {
                                        await presenter.handleRegister()
                                    }
                                }
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, 32)
                        .padding(.bottom, 32)
                    }
                }

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
                        Router.shared.popToRoot()
                    }
                    .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(.vertical, 16)
            }
            .navigationTitle(AppTextAuthRegister.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .dismissKeyboardOnTap()
            .alert(isPresented: $presenter.showRegisterSuccessAlert) {
                Alert(
                    title: Text(AppState.success),
                    message: Text(presenter.registerSuccessMessage),
                    dismissButton: .default(Text(AppAction.ok)) {
                        presenter.prepareForLoginAfterRegister()
                        Router.shared.popToRoot()
                    }
                )
            }
            .alert(
                AppTextAuthRegister.registerFailedText,
                isPresented: Binding(
                    get: { presenter.isError && !presenter.errorMessage.isEmpty },
                    set: { if !$0 {
                        presenter.isError = false
                        presenter.errorMessage = AppValue.empty
                    } }
                ),
                actions: {
                    Button(AppAction.ok) {
                        presenter.isError = false
                        presenter.errorMessage = AppValue.empty
                    }
                },
                message: {
                    Text(presenter.errorMessage)
                }
            )
        }
        .hideBackButton()
        .onDisappear {
            presenter.clearRegistrationForm()
        }
    }
}

#Preview {
    RegisterUserView()
        .environmentObject(DependencyInjection.shared.createAuthPresenter())
}
