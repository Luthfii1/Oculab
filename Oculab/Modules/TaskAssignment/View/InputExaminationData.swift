//
//  InputExaminationData.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 07/11/24.
//

import SwiftUI

struct InputExaminationData: View {
    @ObservedObject var presenter: TaskAssignmentFlowCoordinator
    @State private var submitTask: Task<Void, Never>?
    @State private var bootstrapTask: Task<Void, Never>?

    init(flow: TaskAssignmentFlowCoordinator) {
        self.presenter = flow
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppPopup(
                    image: AppImage.confirm,
                    title: AppTextTaskAssignInputExam.confirmPopupTitle,
                    description: AppTextTaskAssignInputExam.examinationDescription(
                        patientName: presenter.patient.name,
                        picName: presenter.pic.name
                    ),
                    isError: presenter.isError,
                    errorMessage: presenter.errorMessage,
                    buttons: [
                        AppButton(
                            title: AppTextTaskAssignInputExam.createTaskButton,
                            colorType: .primary,
                            size: .large,
                            isEnabled: !presenter.isSubmittingExamination
                        ) {
                            submitTask?.cancel()
                            submitTask = Task {
                                await presenter.submitExamination()
                            }
                        },

                        AppButton(
                            title: AppTextTaskAssignInputExam.reviewAgainButton,
                            colorType: .tertiary,
                            isEnabled: true
                        ) {
                            presenter.hideSubmitPopup()
                            Logger.info("User returned to examination review", category: .taskAssignment)
                        }
                    ],
                    isVisible: $presenter.isSubmitPopUpVisible
                )

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: AppConstants.TaskAssignmentUI.verticalSpacing) {
                            Spacer().frame(height: AppConstants.TaskAssignmentUI.verticalSpacing)

                            AppStepper(
                                stepTitles: AppTextTaskAssignInputExam.stepTitles,
                                currentStep: AppTextTaskAssignInputExam.currentStepIndex
                            )

                            SpecimenContextSummaryCard(
                                patientName: presenter.patient.name,
                                picName: presenter.pic.name
                            )

                            if !presenter.isSpecimenStepReady {
                                Text(AppTextTaskAssignInputExam.completeRequiredHint)
                                    .font(AppTypography.p3)
                                    .foregroundColor(AppColors.slate400)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            examinationPurposeSection
                            slide1Section

                            if presenter.isSlide2Visible {
                                slide2Section
                            }

                            AppButton(
                                title: presenter.slide2ButtonTitle,
                                colorType: presenter.slide2ButtonColor,
                                size: .small,
                                isEnabled: true
                            ) {
                                presenter.toggleSlide2()
                            }
                            .frame(maxWidth: .infinity)

                            Spacer().frame(height: 88)
                        }
                        .padding(.horizontal, AppConstants.TaskAssignmentUI.horizontalPadding)
                    }

                    specimenFooterBar
                }
            }
            .navigationTitle(AppTextTaskAssignInputExam.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Router.shared.endTaskAssignmentFlow()
                        Router.shared.popToRoot()
                    }) {
                        Image(AppImage.destroy)
                    }
                }
            }
            .onAppear {
                bootstrapTask?.cancel()
                bootstrapTask = Task {
                    await presenter.bootstrapSpecimenStep()
                }
            }
            .onDisappear {
                submitTask?.cancel()
                bootstrapTask?.cancel()
            }
            .background(AppColors.slate0)
        }
        .navigationBarBackButtonHidden(true)
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

    // MARK: - Sections

    private var examinationPurposeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppRadioButton(
                title: AppMedical.Examination.purpose,
                isRequired: true,
                choices: [
                    AppTextTaskAssignInputExam.screeningChoice,
                    AppTextTaskAssignInputExam.followUpChoice
                ],
                isDisabled: false,
                selectedChoice: $presenter.goalString
            )
            .onChange(of: presenter.goalString) {
                presenter.handleGoalChange()
            }

            ValidationFieldErrorView(
                fieldName: ValidationFieldName.examinationGoal.fieldName,
                showsErrors: presenter.specimenValidationAttempted,
                validationManager: presenter.validationManager
            )
        }
    }

    private var slide1Section: some View {
        SpecimenFormSection(title: AppTextTaskAssignInputExam.slide1SectionTitle) {
            ValidatedTextField(
                title: AppTextTaskAssignInputExam.slideId1Title,
                isRequired: true,
                placeholder: AppTextTaskAssignInputExam.slideId1Placeholder,
                text: $presenter.examination.slideId,
                fieldName: .slideId1,
                validationType: .required,
                validateOnChange: false,
                showsErrors: presenter.specimenValidationAttempted,
                validationManager: presenter.validationManager
            )

            VStack(alignment: .leading, spacing: 8) {
                AppRadioButton(
                    title: AppTextTaskAssignInputExam.slideType1Title,
                    isRequired: true,
                    choices: [
                        AppTextTaskAssignInputExam.morningChoice,
                        AppTextTaskAssignInputExam.anytimeChoice
                    ],
                    isDisabled: false,
                    selectedChoice: $presenter.typeString
                )
                .onChange(of: presenter.typeString) {
                    presenter.handleFirstSlideTypeChange()
                }

                ValidationFieldErrorView(
                    fieldName: ValidationFieldName.slideType1.fieldName,
                    showsErrors: presenter.specimenValidationAttempted,
                    validationManager: presenter.validationManager
                )
            }
        }
    }

    private var slide2Section: some View {
        SpecimenFormSection(title: AppTextTaskAssignInputExam.slide2SectionTitle) {
            ValidatedTextField(
                title: AppTextTaskAssignInputExam.slideId2Title,
                isRequired: true,
                placeholder: AppTextTaskAssignInputExam.slideId2Placeholder,
                text: $presenter.examination2.slideId,
                fieldName: .slideId2,
                validationType: .required,
                validateOnChange: false,
                showsErrors: presenter.specimenValidationAttempted,
                validationManager: presenter.validationManager
            )

            VStack(alignment: .leading, spacing: 8) {
                AppRadioButton(
                    title: AppTextTaskAssignInputExam.slideType2Title,
                    isRequired: true,
                    choices: [
                        AppTextTaskAssignInputExam.morningChoice,
                        AppTextTaskAssignInputExam.anytimeChoice
                    ],
                    isDisabled: false,
                    selectedChoice: $presenter.typeString2
                )
                .onChange(of: presenter.typeString2) {
                    presenter.handleSecondSlideTypeChange()
                }

                ValidationFieldErrorView(
                    fieldName: ValidationFieldName.slideType2.fieldName,
                    showsErrors: presenter.specimenValidationAttempted,
                    validationManager: presenter.validationManager
                )
            }
        }
    }

    private var specimenFooterBar: some View {
        HStack(spacing: 12) {
            AppButton(
                title: AppAction.back,
                leftIcon: AppIcon.back,
                colorType: .tertiary,
                size: .small,
                isEnabled: true
            ) {
                Router.shared.navigateBack()
            }

            AppButton(
                title: AppTextTaskAssignInputExam.createTaskFinalButton,
                rightIcon: AppIcon.arrowRight,
                colorType: .primary,
                size: .large,
                isEnabled: presenter.isSpecimenStepReady
            ) {
                presenter.showSubmitPopup()
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, AppConstants.TaskAssignmentUI.horizontalPadding)
        .padding(.vertical, 12)
        .background(AppColors.slate0)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

// MARK: - Supporting views

private struct SpecimenContextSummaryCard: View {
    let patientName: String
    let picName: String

    private func displayName(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? AppValue.defaultStrike : trimmed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppTextTaskAssignInputExam.specimenContextTitle)
                .font(AppTypography.s4_1)
                .foregroundColor(AppColors.purple700)

            HStack(alignment: .top, spacing: 16) {
                contextRow(
                    label: AppTextTaskAssignInputExam.specimenContextPatientLabel,
                    value: displayName(patientName),
                    icon: AppIcon.personFill
                )
                contextRow(
                    label: AppTextTaskAssignInputExam.specimenContextPicLabel,
                    value: displayName(picName),
                    icon: AppIcon.personFill
                )
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.purple50)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.purple100, lineWidth: 1)
        )
    }

    private func contextRow(label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(AppTypography.p3)
                .foregroundColor(AppColors.slate400)
            Text(value)
                .font(AppTypography.s4_1)
                .foregroundColor(AppColors.slate900)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SpecimenFormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(AppTypography.s4_1)
                .foregroundColor(AppColors.slate900)

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.slate0)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.slate100, lineWidth: 1)
        )
    }
}
