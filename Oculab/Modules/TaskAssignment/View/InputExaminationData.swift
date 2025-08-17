//
//  InputExaminationData.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 07/11/24.
//

import SwiftUI

struct InputExaminationData: View {
    @ObservedObject var presenter: InputPatientPresenter = .init()
    @State var selectedPIC: String
    @State var selectedPatient: String 

    var body: some View {
        NavigationView {
            ZStack {
                AppPopup(
                    image: AppImage.confirm,
                    title: AppTextTaskAssignInputExam.confirmPopupTitle,
                    description: AppTextTaskAssignInputExam.examinationDescription(patientName: presenter.patient.name, picName: presenter.pic.name),
                    isError: presenter.isError,
                    errorMessage: presenter.errorMessage,
                    buttons: [
                        AppButton(
                            title: AppTextTaskAssignInputExam.createTaskButton,
                            colorType: .primary,
                            size: .large,
                            isEnabled: true
                        ) {
                            Task {
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

                VStack {
                    ScrollView(showsIndicators: false) {
                        VStack {
                            Spacer().frame(height: AppConstants.TaskAssignmentUI.verticalSpacing)

                            AppStepper(stepTitles: AppTextTaskAssignInputExam.stepTitles, currentStep: AppTextTaskAssignInputExam.currentStepIndex)
                            Spacer().frame(height: AppConstants.TaskAssignmentUI.verticalSpacing)

                            VStack(alignment: .leading, spacing: AppConstants.TaskAssignmentUI.verticalSpacing) {
                                AppRadioButton(
                                    title: AppMedical.Examination.purpose,
                                    isRequired: true,
                                    choices: [AppTextTaskAssignInputExam.screeningChoice, AppTextTaskAssignInputExam.followUpChoice],
                                    isDisabled: false,
                                    selectedChoice: $presenter.goalString
                                ).onChange(of: presenter.goalString) {
                                    presenter.handleGoalChange()
                                }

                                ValidatedTextField(
                                    title: AppTextTaskAssignInputExam.slideId1Title,
                                    isRequired: true,
                                    placeholder: AppTextTaskAssignInputExam.slideId1Placeholder,
                                    text: $presenter.examination.slideId,
                                    fieldName: .slideId1,
                                    validationType: .none
                                )

                                AppRadioButton(
                                    title: AppTextTaskAssignInputExam.slideType1Title,
                                    isRequired: true,
                                    choices: [AppTextTaskAssignInputExam.morningChoice, AppTextTaskAssignInputExam.anytimeChoice],
                                    isDisabled: false,
                                    selectedChoice: $presenter.typeString
                                ).onChange(of: presenter.typeString) {
                                    presenter.handleFirstSlideTypeChange()
                                }

                                if presenter.isSlide2Visible {
                                    ValidatedTextField(
                                        title: AppTextTaskAssignInputExam.slideId2Title,
                                        isRequired: false,
                                        placeholder: AppTextTaskAssignInputExam.slideId2Placeholder,
                                        text: $presenter.examination2.slideId,
                                        fieldName: .slideId2,
                                        validationType: .none
                                    )

                                    AppRadioButton(
                                        title: AppTextTaskAssignInputExam.slideType2Title,
                                        isRequired: false,
                                        choices: [AppTextTaskAssignInputExam.morningChoice, AppTextTaskAssignInputExam.anytimeChoice],
                                        isDisabled: false,
                                        selectedChoice: $presenter.typeString2
                                    ).onChange(of: presenter.typeString2) {
                                        presenter.handleSecondSlideTypeChange()
                                    }
                                }
                                
                                AppButton(
                                    title: presenter.slide2ButtonTitle,
                                    colorType: presenter.slide2ButtonColor,
                                    isEnabled: true
                                ) {
                                    presenter.toggleSlide2()
                                }
                                
                                Spacer()
                                
                                HStack {
                                    AppButton(
                                        title: AppAction.back,
                                        leftIcon: AppIcon.back,
                                        colorType: .tertiary,
                                        isEnabled: true
                                    ) {
                                        Router.shared.navigateBack()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(width: UIScreen.main.bounds.width / 3.5)

                                    Spacer()
                                    AppButton(
                                        title: AppTextTaskAssignInputExam.createTaskFinalButton,
                                        rightIcon: AppIcon.arrowRight,
                                        size: .large,
                                        isEnabled: presenter.isFormValid
                                    ) {
                                        presenter.showSubmitPopup()
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }

                            .padding(.horizontal, AppConstants.TaskAssignmentUI.horizontalPadding)
                        }
                        .navigationTitle(AppTextTaskAssignInputExam.navigationTitle)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    Router.shared.popToRoot()
                                }) {
                                    HStack {
                                        Image(AppImage.destroy)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                presenter.setupExaminationData(selectedPIC: selectedPIC, selectedPatient: selectedPatient)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

//#Preview {
//    InputExaminationData(selectedPIC: AppValue.empty, selectedPatient: AppValue.empty)
//}
