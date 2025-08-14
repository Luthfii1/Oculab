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

    var body: some View {
        VStack(alignment: .leading, spacing: Decimal.d24) {
            HStack {
                Image(systemName: AppIcon.photo)
                    .foregroundColor(AppColors.purple500)
                Text(AppTextExam.titleResultInterpretation)
                    .font(AppTypography.s4_1)
                    .padding(.leading, Decimal.d8)
                Spacer()
                StatusTagComponent(type: .NEEDVALIDATION)
            }

            GradingCardComponent(
                type: examination.systemGrading,
                confidenceLevel: presenter.confidenceLevel,
                n: presenter.resultQuantity
            )

            AppDropdown(
                title: AppMedical.Examination.staffInterpretation,
                placeholder: AppForm.selectOption,
                isRequired: false,
                rightIcon: AppIcon.down,
                choices: GradingType.allCases.dropLast().map { ($0.rawValue, $0.rawValue) },
                selectedChoice: $presenter.selectedTBGrade
            )
            .focused($focusedField, equals: .grading)

            if presenter.selectedTBGrade == GradingType.SCANTY.rawValue {
                ValidatedTextField(
                    title: AppMedical.Examination.bacteriaCount,
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
                rightIcon: AppIcon.checkmark,
                isEnabled: presenter.isEnableToSubmit()
            ) {
                presenter.isVerifPopUpVisible = true
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
}
