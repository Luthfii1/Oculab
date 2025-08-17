//
//  InputPatientData.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 07/11/24.
//

import SwiftUI

struct InputPatientData: View {
    let patientId: String?
    @ObservedObject var presenter = InputPatientPresenter()
    @EnvironmentObject private var authentication: AuthenticationPresenter
    
    init(patientId: String? = nil) {
        self.patientId = patientId
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack {
                    Spacer().frame(height: AppConstants.TaskAssignmentUI.verticalSpacing)
                    AppStepper(stepTitles: AppTextTaskAssignInputPatient.stepTitles, currentStep: AppTextTaskAssignInputPatient.currentStepIndex)
                    Spacer().frame(height: AppConstants.TaskAssignmentUI.verticalSpacing)
                    
                    VStack(alignment: .leading, spacing: AppConstants.TaskAssignmentUI.verticalSpacing) {
                        // PIC Dropdown
                        AppDropdown(
                            title: AppTextTaskAssignInputPatient.picTitle,
                            placeholder: AppTextTaskAssignInputPatient.selectPIC,
                            leftIcon: AppIcon.personFill,
                            isDisabled: authentication.isDropdownOfficerDisabled,
                            choices: presenter.picName,
                            isSearchEnabled: false,
                            selectedChoice: $presenter.selectedPIC
                        )
                        .onChange(of: presenter.selectedPIC) { _, _ in
                            // Validation is automatically triggered in the presenter's didSet
                        }
                        
                        // Patient Search Dropdown
                        AppDropdown(
                            title: AppPatient.name,
                            placeholder: patientId != nil ? AppTextTaskAssignInputPatient.patientNamePlaceholder : AppSearch.Patient.placeholder,
                            leftIcon: AppIcon.personFill,
                            rightIcon: AppValue.empty,
                            choices: presenter.patientNameDoB,
                            description: patientId != nil ? AppTextTaskAssignInputPatient.patientNameDescriptionAutoSelected : AppTextTaskAssignInputPatient.patientNameDescription,
                            selectedChoice: $presenter.selectedPatient,
                            isEnablingAdding: patientId == nil
                        )
                        .disabled(patientId != nil)
                        .onChange(of: presenter.selectedPatient) { _, _ in
                            // Validation is automatically triggered in the presenter's didSet
                        }
                        
                        if presenter.selectedPatient != AppValue.empty {
                            PatientDisplayField()
                                .environmentObject(presenter)
                            
                            AppButton(
                                title: AppTextTaskAssignInputPatient.fillSpecimenDetailsButton,
                                rightIcon: AppIcon.arrowForward,
                                isEnabled: presenter.canProceedToSpecimen(userRole: authentication.user.role, businessModel: authentication.user.businessModel ?? .B2C)
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
                            Router.shared.navigateBack()
                        }) {
                            HStack {
                                Image(AppImage.destroy)
                            }
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await presenter.getAllUser()
                    await presenter.getAllPatient()
                    
                    // Auto-fill PIC for B2C LAB users
                    if authentication.user.role == .LAB && authentication.user.businessModel == .B2C {
                        presenter.selectedPIC = authentication.user._id
                    }
                    
                    // Auto-fill patient if patientId is provided
                    if let patientId = patientId, !patientId.isEmpty {
                        await presenter.getPatientById(patientId: patientId)
                        // Set the selected patient to trigger the form display
                        presenter.selectedPatient = patientId
                    }
                }
            }
            .dismissKeyboardOnTap()
            .onChange(of: presenter.selectedPatient) { _, newValue in
                Task {
                    Logger.info("Selected patient changed: \(presenter.selectedPatient)", category: .taskAssignment)
                    // Only fetch if it's not already auto-filled
                    if patientId == nil || newValue != patientId {
                        await presenter.getPatientById(patientId: newValue)
                    }
                }
            }
            .onChange(of: presenter.selectedPIC) { _, newValue in
                if !newValue.isEmpty {
                    Task {
                        await presenter.getUserById(userId: newValue)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
}

//#Preview("With Patient") {
//    InputPatientData(patientId: "d0c1a2b3-4f5e-6789-91ab-cdef12345678")
//}

