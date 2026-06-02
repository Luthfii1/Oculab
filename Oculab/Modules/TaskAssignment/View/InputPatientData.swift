//
//  InputPatientData.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 07/11/24.
//

import SwiftUI

struct InputPatientData: View {
    let patientId: String?
    @ObservedObject var presenter: TaskAssignmentFlowCoordinator
    @EnvironmentObject private var authentication: AuthenticationPresenter
    @State private var loadTask: Task<Void, Never>?
    @State private var patientChangeTask: Task<Void, Never>?
    @State private var picChangeTask: Task<Void, Never>?

    init(patientId: String? = nil, flow: TaskAssignmentFlowCoordinator) {
        self.patientId = patientId
        self.presenter = flow
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack {
                    Spacer().frame(height: AppConstants.TaskAssignmentUI.verticalSpacing)
                    AppStepper(stepTitles: AppTextTaskAssignInputPatient.stepTitles, currentStep: AppTextTaskAssignInputPatient.currentStepIndex)
                    Spacer().frame(height: AppConstants.TaskAssignmentUI.verticalSpacing)
                    
                    VStack(alignment: .leading, spacing: AppConstants.TaskAssignmentUI.verticalSpacing) {
                        AppDropdown(
                            title: AppTextTaskAssignInputPatient.picTitle,
                            placeholder: AppTextTaskAssignInputPatient.selectPIC,
                            leftIcon: AppIcon.personFill,
                            isDisabled: authentication.isDropdownOfficerDisabled || presenter.isInitialLoading,
                            choices: presenter.picName,
                            isSearchEnabled: false,
                            selectedChoice: $presenter.selectedPIC
                        )

                        if presenter.isPatientListEmpty && patientId == nil {
                            InputPatientEmptyListHint()
                        }

                        AppDropdown(
                            title: AppPatient.name,
                            placeholder: patientSearchPlaceholder,
                            leftIcon: AppIcon.personFill,
                            rightIcon: nil,
                            isDisabled: patientId != nil || presenter.isInitialLoading,
                            choices: presenter.patientNameDoB,
                            description: patientDescription,
                            emptyListMessage: presenter.isPatientListEmpty
                                ? AppTextTaskAssignInputPatient.emptyPatientListDropdownHint
                                : nil,
                            selectedChoice: presenter.patientChoiceBinding,
                            isEnablingAdding: patientId == nil
                        )
                        .disabled(patientId != nil)
                        
                        if presenter.hasPatientChoice {
                            PatientDisplayField()
                                .environmentObject(presenter)
                            
                            AppButton(
                                title: proceedButtonTitle,
                                rightIcon: presenter.isSavingPatient ? nil : AppIcon.arrowForward,
                                isEnabled: canProceed && !presenter.isSavingPatient
                            ) {
                                presenter.newExam()
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, AppConstants.TaskAssignmentUI.horizontalPadding)
                }
                .navigationTitle(AppTextTaskAssignInputPatient.navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            Router.shared.endTaskAssignmentFlow()
                            Router.shared.navigateBack()
                        }) {
                            HStack {
                                Image(AppImage.destroy)
                            }
                        }
                    }
                }
            }
            .loadingOverlay(presenter.isInitialLoading, message: AppTextTaskAssignInputPatient.loadingDataMessage)
            .onAppear {
                loadTask?.cancel()
                loadTask = Task {
                    await presenter.getAllUser()
                    await presenter.getAllPatient()
                    await MainActor.run {
                        presenter.markInitialLoadComplete()
                    }

                    if authentication.user.role == .LAB && authentication.user.businessModel == .B2C {
                        let picId = authentication.user._id
                        presenter.selectedPIC = picId
                        await presenter.getUserById(userId: picId)
                    }

                    if let patientId = patientId, !patientId.isEmpty {
                        presenter.patientSelection = .existing(patientId: patientId)
                        await presenter.getPatientById(patientId: patientId)
                    }
                }
            }
            .onDisappear {
                loadTask?.cancel()
                patientChangeTask?.cancel()
                picChangeTask?.cancel()
            }
            .dismissKeyboardOnTap()
            .onChange(of: presenter.patientSelection) { _, _ in
                patientChangeTask?.cancel()
                patientChangeTask = Task {
                    Logger.info("Selected patient changed", category: .taskAssignment)
                    if patientId == nil || presenter.patientSelection?.existingPatientId != patientId {
                        await presenter.handlePatientChoiceChange()
                    }
                }
            }
            .onChange(of: presenter.selectedPIC) { _, newValue in
                if !newValue.isEmpty {
                    picChangeTask?.cancel()
                    picChangeTask = Task {
                        await presenter.getUserById(userId: newValue)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .alert(
            AppState.error,
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

    private var patientSearchPlaceholder: String {
        if patientId != nil {
            return AppTextTaskAssignInputPatient.patientNamePlaceholder
        }
        return AppSearch.Patient.placeholder
    }

    private var patientDescription: String? {
        if patientId != nil {
            return AppTextTaskAssignInputPatient.patientNameDescriptionAutoSelected
        }
        if presenter.isPatientListEmpty {
            return nil
        }
        return AppTextTaskAssignInputPatient.patientNameDescription
    }

    private var proceedButtonTitle: String {
        presenter.isSavingPatient
            ? AppTextTaskAssignInputPatient.savingPatientButtonTitle
            : AppTextTaskAssignInputPatient.fillSpecimenDetailsButton
    }

    private var canProceed: Bool {
        presenter.canProceedToSpecimen(
            userRole: authentication.user.role,
            businessModel: authentication.user.businessModel ?? .B2C
        )
    }
}

// MARK: - Empty list guidance
private struct InputPatientEmptyListHint: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: AppIcon.personFill)
                .foregroundColor(AppColors.purple500)
                .font(.title3)

            Text(AppTextTaskAssignInputPatient.emptyPatientListHint)
                .font(AppTypography.p3)
                .foregroundColor(AppColors.slate700)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.purple50)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.purple100, lineWidth: 1)
        )
    }
}
