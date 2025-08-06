//
//  ConfirmationPopups.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/11/24.
//

import SwiftUI

struct ConfirmationPopups: View {
    @EnvironmentObject var presenter: AnalysisResultPresenter
    @State var examinationId: String

    var body: some View {
        VStack {
            AppPopup(
                image: AppImage.confirmLeave,
                title: AppTextExamCompConfirmPopups.unfinishedExaminationTitle,
                description: AppTextExamCompConfirmPopups.unfinishedExaminationDescription,
                buttons: [
                    AppButton(title: AppTextExamCompConfirmPopups.exitButton, colorType: .destructive(.primary)) {
                        presenter.popToRoot()
                    },
                    AppButton(title: AppTextExamCompConfirmPopups.reviewAgainButton, colorType: .destructive(.secondary)) {
                        presenter.isLeavePopUpVisible = false
                    }
                ],
                isVisible: $presenter.isLeavePopUpVisible
            )

            AppPopup(
                image: AppImage.confirm,
                title: AppTextExamCompConfirmPopups.saveResultTitle,
                description: AppTextExamCompConfirmPopups.saveResultDescription,
                buttons: [
                    AppButton(title: AppTextExamCompConfirmPopups.saveButton, colorType: .primary) {
                        Task {
                            await presenter.submitExpertResult(examinationId: examinationId)
                        }
                    },
                    AppButton(title: AppTextExamCompConfirmPopups.reviewAgainButton, colorType: .tertiary) {
                        presenter.isVerifPopUpVisible = false
                    }
                ],
                isVisible: $presenter.isVerifPopUpVisible
            )
        }
    }
}

#Preview {
    ConfirmationPopups(examinationId: "jalo")
        .environmentObject(AnalysisResultPresenter())
}
