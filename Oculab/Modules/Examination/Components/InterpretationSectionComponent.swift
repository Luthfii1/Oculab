//
//  InterpretationSectionComponent.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/11/24.
//

import SwiftUI

enum AnalysisFocusField {
    case grading
    case countBta
    case notes
}

struct InterpretationSectionComponent: View {
    @EnvironmentObject var presenter: AnalysisResultPresenter
    var examination: ExaminationResultData
    @FocusState var focusedField: AnalysisFocusField?

    private var isCompleted: Bool {
        examination.statusExamination == .FINISHED
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Decimal.d24) {
            HStack {
                Image(systemName: AppIcon.photo)
                    .foregroundColor(AppColors.purple500)
                Text(AppTextExam.titleResultInterpretation)
                    .font(AppTypography.s4_1)
                    .padding(.leading, Decimal.d8)
                Spacer()
                StatusTagComponent(type: isCompleted ? .FINISHED : .NEEDVALIDATION)
            }

            if isCompleted {
                completedContent
            } else {
                validationContent
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(AppAction.done) {
                    focusedField = nil
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(Decimal.d12)
        .overlay(RoundedRectangle(cornerRadius: Decimal.d12).stroke(AppColors.slate100))
        .padding(.horizontal, Decimal.d20)
    }

    private var validationContent: some View {
        Group {
            GradingCardComponent(
                type: examination.systemGrading,
                confidenceLevel: presenter.systemConfidenceLevel,
                n: presenter.systemGradingCount
            )

            AppDropdown(
                title: AppMedical.Examination.staffInterpretation,
                placeholder: AppForm.selectOption,
                isRequired: true,
                rightIcon: AppIcon.down,
                choices: GradingType.allCases.dropLast().map { ($0.displayValue, $0.rawValue) },
                isSearchEnabled: false,
                selectedChoice: $presenter.selectedTBGrade
            )
            .focused($focusedField, equals: .grading)

            if presenter.selectedTBGrade == GradingType.SCANTY.rawValue {
                ValidatedTextField(
                    title: AppMedical.Examination.bacteriaCount,
                    isRequired: true,
                    placeholder: AppTextExamCompInterpretationSection.btaCountPlaceholder,
                    isNumberOnly: true,
                    text: $presenter.numOfBTA,
                    fieldName: .bacteriaCount,
                    validationType: .none
                )
                .focused($focusedField, equals: .countBta)
            }

            AppTextBox(
                title: AppLabel.notes,
                placeholder: AppTextExamCompInterpretationSection.staffNotesPlaceholder,
                text: $presenter.inspectorNotes
            )
            .focused($focusedField, equals: .notes)

            AppButton(
                title: presenter.buttonTitle,
                rightIcon: presenter.isAllFOVsVerified ? AppIcon.checkmark : AppIcon.arrowRight,
                isEnabled: presenter.isPrimaryActionEnabled()
            ) {
                presenter.handlePrimaryValidationAction()
            }
        }
    }

    private var completedContent: some View {
        Group {
            VStack(alignment: .leading, spacing: Decimal.d8) {
                Text(AppMedical.Examination.staffInterpretation)
                    .font(AppTypography.s5)
                    .foregroundColor(AppColors.slate300)
                GradingCardComponent(
                    type: examination.expertGrading ?? .unknown,
                    isExpert: true,
                    expertNote: examination.expertNote
                )
            }

            VStack(alignment: .leading, spacing: Decimal.d8) {
                Text(AppMedical.Examination.systemInterpretation)
                    .font(AppTypography.s5)
                    .foregroundColor(AppColors.slate300)
                HStack(alignment: .top) {
                    Image(systemName: AppIcon.warning)
                        .foregroundColor(AppColors.orange500)
                    Text(AppTextExamSavedResult.systemInterpretationWarning)
                        .font(AppTypography.p4)
                }
                GradingCardComponent(
                    type: examination.systemGrading,
                    confidenceLevel: presenter.systemConfidenceLevel,
                    n: presenter.systemGradingCount
                )
            }

            AppButton(
                title: AppTextExamSavedResult.actionViewPdf,
                rightIcon: AppIcon.document,
                colorType: .secondary,
                size: .small,
                isEnabled: true
            ) {
                presenter.navigateToPDFView()
            }
        }
    }
}
