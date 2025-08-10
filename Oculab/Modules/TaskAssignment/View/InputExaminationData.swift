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
    @State var goalString: String = AppValue.empty
    @State var typeString: String = AppValue.empty

    @State var typeString2: String = AppValue.empty

    @State var isAddingNewPatient: Bool = false

    @State var isSubmitPopUpVisible: Bool = false

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
                            isSubmitPopUpVisible = false
                            print("Kembali ke Pemeriksaan")
                        }
                    ],
                    isVisible: $isSubmitPopUpVisible
                )

                VStack {
                    ScrollView(showsIndicators: false) {
                        VStack {
                            Spacer().frame(height: Decimal.d24)

                            AppStepper(stepTitles: AppTextTaskAssignInputExam.stepTitles, currentStep: AppTextTaskAssignInputExam.currentStepIndex)
                            Spacer().frame(height: Decimal.d24)

                            VStack(alignment: .leading, spacing: Decimal.d24) {
                                AppRadioButton(
                                    title: AppMedical.Examination.purpose,
                                    isRequired: true,
                                    choices: [AppTextTaskAssignInputExam.screeningChoice, AppTextTaskAssignInputExam.followUpChoice],
                                    isDisabled: false,
                                    selectedChoice: $goalString
                                ).onChange(of: goalString) {
                                    switch goalString {
                                    case AppMedical.Examination.goalScreening:
                                        presenter.examination.goal = .SCREENING
                                        presenter.examination2.goal = .SCREENING

                                    case AppMedical.Examination.goalFollowUp:
                                        presenter.examination.goal = .TREATMENT
                                        presenter.examination2.goal = .TREATMENT

                                    default:
                                        presenter.examination.goal = .SCREENING
                                        presenter.examination2.goal = .SCREENING
                                    }
                                }

                                AppTextField(
                                    title: AppTextTaskAssignInputExam.slideId1Title,
                                    placeholder: AppTextTaskAssignInputExam.slideId1Placeholder,
                                    text: $presenter.examination.slideId
                                )

                                AppRadioButton(
                                    title: AppTextTaskAssignInputExam.slideType1Title,
                                    isRequired: true,
                                    choices: [AppTextTaskAssignInputExam.morningChoice, AppTextTaskAssignInputExam.anytimeChoice],
                                    isDisabled: false,
                                    selectedChoice: $typeString
                                ).onChange(of: typeString) {
                                    switch typeString {
                                    case AppMedical.Examination.preparationTypeMorning:
                                        presenter.examination.preparationType = .SP
                                    case AppMedical.Examination.preparationTypeAnytime:
                                        presenter.examination.preparationType = .SPS
                                    default:
                                        presenter.examination.preparationType = .SPS
                                    }
                                }

                                AppTextField(
                                    title: AppTextTaskAssignInputExam.slideId2Title,
                                    placeholder: AppTextTaskAssignInputExam.slideId2Placeholder,
                                    text: $presenter.examination2.slideId
                                )

                                AppRadioButton(
                                    title: AppTextTaskAssignInputExam.slideType2Title,
                                    isRequired: true,
                                    choices: [AppTextTaskAssignInputExam.morningChoice, AppTextTaskAssignInputExam.anytimeChoice],
                                    isDisabled: false,
                                    selectedChoice: $typeString2
                                ).onChange(of: typeString2) {
                                    switch typeString2 {
                                    case AppMedical.Examination.preparationTypeMorning:
                                        presenter.examination2.preparationType = .SP
                                    case AppMedical.Examination.preparationTypeAnytime:
                                        presenter.examination2.preparationType = .SPS
                                    default:
                                        presenter.examination2.preparationType = .SPS
                                    }
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
                                        isEnabled: (goalString != AppValue.empty && typeString != AppValue.empty && presenter.examination.slideId != AppValue.empty && typeString2 != AppValue.empty && presenter.examination2.slideId != AppValue.empty)
                                    ) {
                                        presenter.isError = false
                                        presenter.errorMessage = AppValue.empty
                                        isSubmitPopUpVisible = true
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }

                            .padding(.horizontal, Decimal.d20)
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
                Task {
                    await presenter.getPatientById(patientId: selectedPatient)
                    print(selectedPatient)
                    print(presenter.patient.name)
                    await presenter.getUserById(userId: selectedPIC)

                    print(presenter.patient.name)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    InputExaminationData(selectedPIC: AppValue.empty, selectedPatient: AppValue.empty)
}
